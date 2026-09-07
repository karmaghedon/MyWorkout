import Foundation
import HealthKit

/// Thin wrapper over `HKHealthStore`'s authorization request. Kept
/// separate from any HealthKit read/write service so a screen can check
/// "is authorization even possible on this device" and trigger the
/// system permission sheet without depending on the (larger, harder to
/// mock) body-metrics/nutrition service protocols.
@MainActor
final class HealthKitAuthorizationManager: ObservableObject {
    @Published private(set) var isHealthDataAvailable: Bool

    private let healthStore: HKHealthStore?

    init() {
        let isAvailable = HKHealthStore.isHealthDataAvailable()
        isHealthDataAvailable = isAvailable
        healthStore = isAvailable ? HKHealthStore() : nil
    }

    /// Requests every type in `HealthKitTypeCatalog` at once. A no-op on
    /// a device without Health data (e.g. iPad).
    func requestAuthorization() async throws {
        guard let healthStore else { return }

        try await healthStore.requestAuthorization(
            toShare: HealthKitTypeCatalog.shareTypes,
            read: HealthKitTypeCatalog.readTypes
        )
    }
}
