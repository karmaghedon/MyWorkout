import Foundation

/// A single dated measurement — one HealthKit sample's date and value,
/// or one local `BodyMeasurementLog`'s date and neck reading. The
/// common shape `WeeklyBodyReportEngine` aggregates over, regardless of
/// which store or service the reading originally came from.
struct DatedValue: Equatable {
    let date: Date
    let value: Double
}
