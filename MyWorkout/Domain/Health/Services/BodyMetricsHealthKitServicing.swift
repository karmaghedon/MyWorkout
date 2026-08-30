import Foundation

/// Narrow protocol boundary around HealthKit body-metrics writes.
///
/// Hard rule (see the project's health-tracking plan): no test may ever
/// construct the real `HKHealthStore`-backed `BodyMetricsHealthKitService`
/// — a test touching real HealthKit can pop real permission dialogs and
/// write real rows into the user's actual Health app. Any logic test
/// exercises a mock conforming to this protocol instead.
protocol BodyMetricsHealthKitServicing {
    /// Writes weight (required) and, when provided, body fat % and waist
    /// circumference to HealthKit. `bodyFatPercent` is a 0–100 value
    /// (converted internally to HealthKit's expected 0–1 fraction).
    func logWeight(
        kg: Double,
        bodyFatPercent: Double?,
        waistCm: Double?,
        date: Date
    ) async throws
}
