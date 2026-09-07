import Foundation

/// Produces a smoothed trend line from noisy daily samples (e.g. daily
/// weigh-ins, which swing with water weight/food/time-of-day) — a
/// trailing moving average, matching the "Тренд" line in the reference
/// design this was built to match. Pure function, no dependencies.
enum TrendSmoother {
    /// For each input point, averages every point whose date falls
    /// within the trailing `windowDays` (inclusive of the point itself).
    /// Points remain in the same order and at the same dates as the
    /// input — only the values are smoothed.
    static func movingAverage(
        _ points: [DatedValue],
        windowDays: Int = 7
    ) -> [DatedValue] {
        guard windowDays > 0 else { return points }

        let sorted = points.sorted { $0.date < $1.date }
        let calendar = Calendar.current

        return sorted.map { point in
            guard let windowStart = calendar.date(
                byAdding: .day,
                value: -(windowDays - 1),
                to: point.date
            ) else {
                return point
            }

            let windowValues = sorted
                .filter { $0.date >= windowStart && $0.date <= point.date }
                .map(\.value)

            let average = windowValues.reduce(0, +) / Double(windowValues.count)

            return DatedValue(date: point.date, value: average)
        }
    }
}
