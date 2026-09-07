import Foundation

/// Narrow protocol boundary around HealthKit body-metrics writes.
///
/// Hard rule (see the project's health-tracking plan): no test may ever
/// construct the real `HKHealthStore`-backed `BodyMetricsHealthKitService`
/// — a test touching real HealthKit can pop real permission dialogs and
/// write real rows into the user's actual Health app. Any logic test
/// exercises a mock conforming to this protocol instead.
protocol BodyMetricsHealthKitServicing {
    /// Writes a weigh-in to HealthKit. Weight only — this app no longer
    /// collects body fat % or waist on the daily weigh-in screen: body
    /// fat % is always calculated (`NavyBodyFatCalculator`), never
    /// entered, and waist is a weekly measurement logged separately via
    /// `logWaist(cm:date:)`.
    func logWeight(
        kg: Double,
        date: Date
    ) async throws

    /// Writes a waist-circumference reading to HealthKit. Logged
    /// weekly, not daily — see `LogBodyMeasurementsView`.
    func logWaist(
        cm: Double,
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

    /// Deletes the waist-circumference sample with this exact start
    /// date — `date` must be a value previously returned by
    /// `waistSamples(since:)`, not an arbitrary calendar day (there can
    /// be more than one sample on the same day). Used to correct or
    /// remove a past entry from the measurement history screen.
    func deleteWaistSample(date: Date) async throws
}
