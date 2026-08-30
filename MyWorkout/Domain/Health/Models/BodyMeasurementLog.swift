import Foundation

/// A body measurement that HealthKit has no quantity type for. Weight,
/// body fat %, and waist all live in HealthKit directly (see
/// `BodyMetricsHealthKitServicing`) — this only exists for the one field
/// that has nowhere else to go.
struct BodyMeasurementLog: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let neckCm: Double

    init(
        id: UUID = UUID(),
        date: Date,
        neckCm: Double
    ) {
        self.id = id
        self.date = date
        self.neckCm = neckCm
    }
}
