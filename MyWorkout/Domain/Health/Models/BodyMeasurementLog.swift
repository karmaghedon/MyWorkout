import Foundation

/// Body measurements that HealthKit has no quantity type for. Weight,
/// body fat %, and waist all live in HealthKit directly (see
/// `BodyMetricsHealthKitServicing`) — this only exists for the fields
/// that have nowhere else to go: neck (everyone) and hip (needed only
/// for the women's U.S. Navy body-fat formula, so optional).
///
/// Both fields are optional so a single toggle-gated entry screen
/// (`LogWeightView`) can save a record when the user logs just one of
/// them — `neckCm`/`hipCm` being `Optional` is why the compiler-
/// synthesized `Codable` conformance already tolerates older
/// persisted/backed-up records that predate `hipCm` with no custom
/// decoder needed.
struct BodyMeasurementLog: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let neckCm: Double?
    let hipCm: Double?

    init(
        id: UUID = UUID(),
        date: Date,
        neckCm: Double? = nil,
        hipCm: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.neckCm = neckCm
        self.hipCm = hipCm
    }
}
