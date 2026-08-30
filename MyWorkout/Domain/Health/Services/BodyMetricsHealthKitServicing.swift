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

    /// All weight samples (in kilograms) recorded on or after `date`,
    /// oldest first. Feeds `WeeklyBodyReportEngine`.
    func weightSamples(since date: Date) async throws -> [DatedValue]

    /// All waist-circumference samples (in centimeters) recorded on or
    /// after `date`, oldest first. Feeds `WeeklyBodyReportEngine`.
    func waistSamples(since date: Date) async throws -> [DatedValue]

    /// All body fat % samples (0–100 scale, converted back from
    /// HealthKit's 0–1 fraction) recorded on or after `date`, oldest
    /// first. A day with no sample here means the user never entered or
    /// synced a direct reading for it — `NavyBodyFatCalculator` fills
    /// that gap from waist/neck/hip instead.
    func bodyFatPercentSamples(since date: Date) async throws -> [DatedValue]
}
