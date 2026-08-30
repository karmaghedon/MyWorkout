import Foundation

/// Computed, never persisted — `reload(neckLogs:)` re-fetches weight/waist
/// from HealthKit and feeds them plus the caller-supplied local neck logs
/// into `WeeklyBodyReportEngine`. Neck logs are passed in rather than
/// injected as a `BodyMeasurementLogStore` dependency at init time, since
/// `@StateObject` properties in `MyWorkoutApp` can't reference sibling
/// `@StateObject` properties during initialization — the caller (a View,
/// which already holds both as `@EnvironmentObject`s) bridges the two.
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

    func reload(neckLogs: [BodyMeasurementLog]) async {
        isLoading = true

        do {
            let weight = try await healthKitService.weightSamples(since: .distantPast)
            let waist = try await healthKitService.waistSamples(since: .distantPast)
            let neck = neckLogs.map { DatedValue(date: $0.date, value: $0.neckCm) }

            cards = WeeklyBodyReportEngine.reportCards(bodyMass: weight, waist: waist, neck: neck)
            loadError = nil
        } catch {
            loadError = "Couldn't load your weekly report: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
