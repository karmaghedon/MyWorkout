import Foundation

/// Pure aggregation over raw dated samples — no HealthKit or persistence
/// dependency, fully unit-testable with fixture arrays (see
/// `WeeklyBodyReportEngineTests`).
///
/// Windows are grouped by actual weigh-in cadence, not fixed calendar
/// weeks: each window starts on a real weight-sample date and extends
/// either to the next weight-sample date that is at least 7 days later,
/// or to the day after the last sample overall (closing the final
/// window). This means windows are "~7 days but stretch to the next
/// actual log" — never a degenerate same-day sliver, and never assuming
/// a weigh-in landed on a fixed calendar boundary.
enum WeeklyBodyReportEngine {
    static func reportCards(
        bodyMass: [DatedValue],
        waist: [DatedValue],
        neck: [DatedValue]
    ) -> [WeeklyBodyReportCard] {
        let sortedWeightDates = bodyMass.map(\.date).sorted()

        guard let firstDate = sortedWeightDates.first,
              let lastDate = sortedWeightDates.last else {
            return []
        }

        let calendar = Calendar.current
        var windows: [(start: Date, end: Date)] = []
        var windowStart = firstDate

        while windowStart <= lastDate {
            let nominalEnd = calendar.date(byAdding: .day, value: 7, to: windowStart)!
            let nextBoundary = sortedWeightDates.first { $0 >= nominalEnd }
                ?? calendar.date(byAdding: .day, value: 1, to: lastDate)!

            windows.append((start: windowStart, end: nextBoundary))
            windowStart = nextBoundary
        }

        var cards: [WeeklyBodyReportCard] = []
        var previousCard: WeeklyBodyReportCard?

        for window in windows {
            let weightsInWindow = bodyMass
                .filter { $0.date >= window.start && $0.date < window.end }
                .map(\.value)

            guard !weightsInWindow.isEmpty else { continue }

            let weightMin = weightsInWindow.min()!
            let weightMax = weightsInWindow.max()!
            let weightAvg = weightsInWindow.reduce(0, +) / Double(weightsInWindow.count)
            let weightAvgDelta = previousCard.map { weightAvg - $0.weightAvg }

            let waistLatest = latestValue(waist, in: window)
            let waistDelta = delta(current: waistLatest, previous: previousCard?.waistLatest)

            let neckLatest = latestValue(neck, in: window)
            let neckDelta = delta(current: neckLatest, previous: previousCard?.neckLatest)

            let card = WeeklyBodyReportCard(
                windowStart: window.start,
                windowEnd: window.end,
                weightMin: weightMin,
                weightMax: weightMax,
                weightAvg: weightAvg,
                weightAvgDelta: weightAvgDelta,
                waistLatest: waistLatest,
                waistDelta: waistDelta,
                neckLatest: neckLatest,
                neckDelta: neckDelta
            )

            cards.append(card)
            previousCard = card
        }

        return cards
    }

    private static func latestValue(
        _ samples: [DatedValue],
        in window: (start: Date, end: Date)
    ) -> Double? {
        samples
            .filter { $0.date >= window.start && $0.date < window.end }
            .max { $0.date < $1.date }?
            .value
    }

    private static func delta(current: Double?, previous: Double?) -> Double? {
        guard let current, let previous else { return nil }
        return current - previous
    }
}
