import Foundation
import HealthKit

final class BodyMetricsHealthKitService: BodyMetricsHealthKitServicing {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func logWeight(
        kg: Double,
        bodyFatPercent: Double?,
        waistCm: Double?,
        date: Date
    ) async throws {
        var samples: [HKQuantitySample] = [
            HKQuantitySample(
                type: HealthKitTypeCatalog.bodyMassType,
                quantity: HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg),
                start: date,
                end: date
            )
        ]

        if let bodyFatPercent {
            samples.append(
                HKQuantitySample(
                    type: HealthKitTypeCatalog.bodyFatPercentageType,
                    // HealthKit expects a 0-1 fraction, not 0-100.
                    quantity: HKQuantity(unit: .percent(), doubleValue: bodyFatPercent / 100),
                    start: date,
                    end: date
                )
            )
        }

        if let waistCm {
            samples.append(
                HKQuantitySample(
                    type: HealthKitTypeCatalog.waistCircumferenceType,
                    quantity: HKQuantity(unit: .meterUnit(with: .centi), doubleValue: waistCm),
                    start: date,
                    end: date
                )
            )
        }

        try await healthStore.save(samples)
    }

    func weightSamples(since date: Date) async throws -> [DatedValue] {
        try await samples(
            type: HealthKitTypeCatalog.bodyMassType,
            unit: .gramUnit(with: .kilo),
            since: date
        )
    }

    func waistSamples(since date: Date) async throws -> [DatedValue] {
        try await samples(
            type: HealthKitTypeCatalog.waistCircumferenceType,
            unit: .meterUnit(with: .centi),
            since: date
        )
    }

    func bodyFatPercentSamples(since date: Date) async throws -> [DatedValue] {
        let fractions = try await samples(
            type: HealthKitTypeCatalog.bodyFatPercentageType,
            unit: .percent(),
            since: date
        )

        // HealthKit stores a 0-1 fraction; every other body fat %
        // value in this app (LogWeightView's input, NavyBodyFatCalculator's
        // output) is 0-100.
        return fractions.map { DatedValue(date: $0.date, value: $0.value * 100) }
    }

    private func samples(
        type: HKQuantityType,
        unit: HKUnit,
        since date: Date
    ) async throws -> [DatedValue] {
        let predicate = HKQuery.predicateForSamples(
            withStart: date,
            end: .now,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let values = (samples as? [HKQuantitySample] ?? []).map {
                    DatedValue(date: $0.startDate, value: $0.quantity.doubleValue(for: unit))
                }

                continuation.resume(returning: values)
            }

            healthStore.execute(query)
        }
    }
}
