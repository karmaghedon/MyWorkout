import Foundation
import HealthKit

/// One-time correction for `HistoricalWeeklyDataImporter`'s second run
/// (Aug 24 + Aug 31, 2026): that run wrote waist on a different day than
/// neck for the Aug 24 week, which broke `NavyBodyFatCalculator
/// .fillGaps` (it only computes an estimate for a day that has *both*
/// a waist and a neck reading — same calendar day, not just "somewhere
/// in the same report window"). It also wrote an Aug 31 week the user
/// hasn't actually logged yet (they'll submit it this weekend).
///
/// This deletes exactly the samples that earlier run wrote — matched
/// by exact date *and* value, never a broad date-range wipe — then
/// re-imports a corrected Aug 24 week only. Not a general-purpose tool;
/// delete this file once run (see the commit that removes it).
enum HistoricalDataFixup {
    struct FixupResult {
        var deletedWeightSamples = 0
        var deletedWaistSamples = 0
        var deletedNeckLogs = 0
        var reimportedWeeks = 0
        var errors: [String] = []
    }

    @MainActor
    static func run(
        bodyMeasurementLogStore: BodyMeasurementLogStore
    ) async -> FixupResult {
        let healthStore = HKHealthStore()
        let calendar = Calendar.current
        var result = FixupResult()

        // MARK: Delete exactly what the previous run wrote

        let badWeightSamples: [(kg: Double, components: DateComponents)] = [
            (85.9, DateComponents(year: 2026, month: 8, day: 24)),
            (86.7, DateComponents(year: 2026, month: 8, day: 27)),
            (86.5, DateComponents(year: 2026, month: 8, day: 31)),
            (87.9, DateComponents(year: 2026, month: 9, day: 3))
        ]

        for bad in badWeightSamples {
            guard let day = calendar.date(from: bad.components) else { continue }

            do {
                let deleted = try await deleteMatchingSamples(
                    healthStore: healthStore,
                    type: HealthKitTypeCatalog.bodyMassType,
                    unit: .gramUnit(with: .kilo),
                    approximateValue: bad.kg,
                    on: day,
                    calendar: calendar
                )
                result.deletedWeightSamples += deleted
            } catch {
                result.errors.append("weight delete \(bad.components): \(error.localizedDescription)")
            }
        }

        let badWaistSamples: [(cm: Double, components: DateComponents)] = [
            (85, DateComponents(year: 2026, month: 8, day: 27)),
            (85, DateComponents(year: 2026, month: 9, day: 3))
        ]

        for bad in badWaistSamples {
            guard let day = calendar.date(from: bad.components) else { continue }

            do {
                let deleted = try await deleteMatchingSamples(
                    healthStore: healthStore,
                    type: HealthKitTypeCatalog.waistCircumferenceType,
                    unit: .meterUnit(with: .centi),
                    approximateValue: bad.cm,
                    on: day,
                    calendar: calendar
                )
                result.deletedWaistSamples += deleted
            } catch {
                result.errors.append("waist delete \(bad.components): \(error.localizedDescription)")
            }
        }

        let badNeckDays: [DateComponents] = [
            DateComponents(year: 2026, month: 8, day: 24),
            DateComponents(year: 2026, month: 8, day: 31)
        ]

        var remainingLogs = bodyMeasurementLogStore.logs
        for badDay in badNeckDays {
            guard let day = calendar.date(from: badDay) else { continue }

            let before = remainingLogs.count
            remainingLogs.removeAll { log in
                calendar.isDate(log.date, inSameDayAs: day) && log.neckCm == 40 && log.hipCm == nil
            }
            result.deletedNeckLogs += before - remainingLogs.count
        }
        bodyMeasurementLogStore.replaceAll(with: remainingLogs)

        // MARK: Re-import a corrected Aug 24 week (waist + neck same
        // day; Aug 31 deliberately not re-added)

        guard let weekDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 24)) else {
            return result
        }

        // +6 days, not +3: keeps the second synthetic weight sample
        // strictly inside this week's own window (nominal end is
        // weekDate + 7), so it can never be mistaken for the start of
        // the *next* window the way a real future weigh-in landing at
        // weekDate + 3..6 could.
        let secondSampleDate = calendar.date(byAdding: .day, value: 6, to: weekDate) ?? weekDate
        let avgKg = 86.3
        let minKg = 85.9
        let secondKg = 2 * avgKg - minKg

        do {
            try await save(healthStore: healthStore, type: HealthKitTypeCatalog.bodyMassType, unit: .gramUnit(with: .kilo), value: minKg, date: weekDate)
            try await save(healthStore: healthStore, type: HealthKitTypeCatalog.bodyMassType, unit: .gramUnit(with: .kilo), value: secondKg, date: secondSampleDate)
            try await save(healthStore: healthStore, type: HealthKitTypeCatalog.waistCircumferenceType, unit: .meterUnit(with: .centi), value: 85, date: weekDate)

            bodyMeasurementLogStore.add(BodyMeasurementLog(date: weekDate, neckCm: 40))

            result.reimportedWeeks = 1
        } catch {
            result.errors.append("reimport: \(error.localizedDescription)")
        }

        return result
    }

    private static func deleteMatchingSamples(
        healthStore: HKHealthStore,
        type: HKQuantityType,
        unit: HKUnit,
        approximateValue: Double,
        on day: Date,
        calendar: Calendar
    ) async throws -> Int {
        let startOfDay = calendar.startOfDay(for: day)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
            }

            healthStore.execute(query)
        }

        let matching = samples.filter { abs($0.quantity.doubleValue(for: unit) - approximateValue) < 0.05 }

        guard !matching.isEmpty else { return 0 }

        try await healthStore.delete(matching)
        return matching.count
    }

    private static func save(
        healthStore: HKHealthStore,
        type: HKQuantityType,
        unit: HKUnit,
        value: Double,
        date: Date
    ) async throws {
        let sample = HKQuantitySample(
            type: type,
            quantity: HKQuantity(unit: unit, doubleValue: value),
            start: date,
            end: date
        )

        try await healthStore.save([sample])
    }
}
