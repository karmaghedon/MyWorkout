import Foundation

/// Narrow protocol boundary around HealthKit activity reads. Separate
/// from `BodyMetricsHealthKitServicing` — steps are activity data, not
/// a body metric, and this app never writes step counts, only reads
/// what the phone/watch already recorded.
///
/// Hard rule (see the project's health-tracking plan): no test may ever
/// construct the real `HKHealthStore`-backed `ActivityHealthKitService`
/// — a test touching real HealthKit can pop real permission dialogs.
/// Any logic test exercises a mock conforming to this protocol instead.
protocol ActivityHealthKitServicing {
    /// One value per calendar day (summed from however many step
    /// samples the phone/watch recorded that day) from `date` through
    /// today, oldest first.
    func dailyStepTotals(since date: Date) async throws -> [DatedValue]
}
