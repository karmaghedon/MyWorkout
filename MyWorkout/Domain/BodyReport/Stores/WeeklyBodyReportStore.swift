import Foundation

/// Computed, never persisted — `reload(bodyMeasurementLogs:sex:heightCm:)`
/// re-fetches weight/waist/body-fat-% from HealthKit and feeds them plus
/// the caller-supplied local neck/hip logs into `WeeklyBodyReportEngine`.
/// Neck/hip logs, sex, and height are all passed in rather than injected
/// as dependencies at init time, since `@StateObject` properties in
/// `MyWorkoutApp` can't reference sibling `@StateObject` properties
/// during initialization — the caller (a View, which already holds
/// `BodyMeasurementLogStore` and `UserSettingsStore` as
/// `@EnvironmentObject`s) bridges them.
///
/// `.task`-loaded on view appear; there is no live `HKObserverQuery` push,
/// so a change made in Apple's Health app directly won't appear until the
/// next time `WeeklyReportView` is opened. Documented future extension,
/// not needed for v1.
@MainActor
final class WeeklyBodyReportStore: ObservableObject {
    @Published private(set) var cards: [WeeklyBodyReportCard] = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?

    private let healthKitService: any BodyMetricsHealthKitServicing

    init(
        healthKitService: any BodyMetricsHealthKitServicing = BodyMetricsHealthKitService()
    ) {
        self.healthKitService = healthKitService
    }

    func reload(
        bodyMeasurementLogs: [BodyMeasurementLog],
        sex: BiologicalSex?,
        heightCm: Double?
    ) async {
        isLoading = true

        do {
            let weight = try await healthKitService.weightSamples(since: .distantPast)
            let waist = try await healthKitService.waistSamples(since: .distantPast)
            let actualBodyFatPercent = try await healthKitService.bodyFatPercentSamples(since: .distantPast)

            let neck = bodyMeasurementLogs.compactMap { log -> DatedValue? in
                guard let neckCm = log.neckCm else { return nil }
                return DatedValue(date: log.date, value: neckCm)
            }
            let hip = bodyMeasurementLogs.compactMap { log -> DatedValue? in
                guard let hipCm = log.hipCm else { return nil }
                return DatedValue(date: log.date, value: hipCm)
            }

            let bodyFatPercent = NavyBodyFatCalculator.fillGaps(
                actual: actualBodyFatPercent,
                waist: waist,
                neck: neck,
                hip: hip,
                sex: sex,
                heightCm: heightCm
            )

            cards = WeeklyBodyReportEngine.reportCards(
                bodyMass: weight,
                waist: waist,
                neck: neck,
                bodyFatPercent: bodyFatPercent
            )
            loadError = nil
        } catch {
            loadError = "Couldn't load your weekly report: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
