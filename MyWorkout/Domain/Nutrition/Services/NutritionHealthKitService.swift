import Foundation
import HealthKit

final class NutritionHealthKitService: NutritionHealthKitServicing {
    /// Marks a sample as "this app's rolled-up daily total" so a later
    /// edit can find and delete exactly those samples before writing
    /// fresh ones, without touching any dietary data other apps or Apple
    /// Health itself may have written for the same day.
    private static let dailyTotalMetadataKey = "com.myworkout.dailyNutritionTotal"

    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func logDailyTotals(
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        calories: Double,
        date: Date
    ) async throws {
        try await deleteExistingDailyTotals(for: date)

        let metadata = [Self.dailyTotalMetadataKey: true]

        let samples = [
            HKQuantitySample(
                type: HealthKitTypeCatalog.dietaryEnergyType,
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                start: date,
                end: date,
                metadata: metadata
            ),
            HKQuantitySample(
                type: HealthKitTypeCatalog.dietaryProteinType,
                quantity: HKQuantity(unit: .gramUnit(with: .none), doubleValue: proteinG),
                start: date,
                end: date,
                metadata: metadata
            ),
            HKQuantitySample(
                type: HealthKitTypeCatalog.dietaryCarbohydratesType,
                quantity: HKQuantity(unit: .gramUnit(with: .none), doubleValue: carbsG),
                start: date,
                end: date,
                metadata: metadata
            ),
            HKQuantitySample(
                type: HealthKitTypeCatalog.dietaryFatTotalType,
                quantity: HKQuantity(unit: .gramUnit(with: .none), doubleValue: fatG),
                start: date,
                end: date,
                metadata: metadata
            )
        ]

        try await healthStore.save(samples)
    }

    private func deleteExistingDailyTotals(for date: Date) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let datePredicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        let metadataPredicate = HKQuery.predicateForObjects(
            withMetadataKey: Self.dailyTotalMetadataKey,
            allowedValues: [true]
        )
        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [datePredicate, metadataPredicate]
        )

        let types = [
            HealthKitTypeCatalog.dietaryEnergyType,
            HealthKitTypeCatalog.dietaryProteinType,
            HealthKitTypeCatalog.dietaryCarbohydratesType,
            HealthKitTypeCatalog.dietaryFatTotalType
        ]

        for type in types {
            let samples = try await existingSamples(type: type, predicate: predicate)

            guard !samples.isEmpty else { continue }

            try await healthStore.delete(samples)
        }
    }

    private func existingSamples(
        type: HKQuantityType,
        predicate: NSPredicate
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
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

                continuation.resume(returning: samples ?? [])
            }

            healthStore.execute(query)
        }
    }
}
