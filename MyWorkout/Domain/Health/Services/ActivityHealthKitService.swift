import Foundation
import HealthKit

final class ActivityHealthKitService: ActivityHealthKitServicing {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func dailyStepTotals(since date: Date) async throws -> [DatedValue] {
        let calendar = Calendar.current
        let startOfFirstDay = calendar.startOfDay(for: date)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfFirstDay,
            end: .now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: HealthKitTypeCatalog.stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startOfFirstDay,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results else {
                    continuation.resume(returning: [])
                    return
                }

                var values: [DatedValue] = []

                results.enumerateStatistics(from: startOfFirstDay, to: .now) { statistics, _ in
                    guard let sum = statistics.sumQuantity() else { return }
                    values.append(
                        DatedValue(date: statistics.startDate, value: sum.doubleValue(for: .count()))
                    )
                }

                continuation.resume(returning: values)
            }

            healthStore.execute(query)
        }
    }
}
