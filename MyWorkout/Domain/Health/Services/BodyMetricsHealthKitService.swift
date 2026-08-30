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
}
