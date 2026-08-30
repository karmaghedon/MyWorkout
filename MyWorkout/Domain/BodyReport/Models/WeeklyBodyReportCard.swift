import Foundation

/// A single window's aggregated body-metrics summary. Never persisted —
/// `WeeklyBodyReportEngine` recomputes the full set from raw samples
/// every time.
struct WeeklyBodyReportCard: Identifiable, Equatable {
    var id: Date { windowStart }

    /// Inclusive.
    let windowStart: Date
    /// Exclusive.
    let windowEnd: Date

    let weightMin: Double
    let weightMax: Double
    let weightAvg: Double
    /// `weightAvg` minus the previous window's `weightAvg`. `nil` for the
    /// first window, since there is nothing to compare against.
    let weightAvgDelta: Double?

    /// The most recent waist reading within the window, not an average —
    /// waist is logged far less often than weight, so averaging it would
    /// wash out a real reading with stale zeros. `nil` if no waist
    /// reading fell within the window.
    let waistLatest: Double?
    /// `waistLatest` minus the previous window's `waistLatest`. `nil` if
    /// either window is missing a waist reading.
    let waistDelta: Double?

    /// Same reasoning as `waistLatest`, for neck.
    let neckLatest: Double?
    let neckDelta: Double?
}
