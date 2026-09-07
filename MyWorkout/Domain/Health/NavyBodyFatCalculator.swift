import Foundation

/// Estimates body fat % from circumference measurements via the U.S.
/// Navy method (±3–4% accuracy vs. hydrostatic weighing). Pure function,
/// no HealthKit or persistence dependency — the same "computed, never
/// stored, fully unit-testable" shape as `WeeklyBodyReportEngine`.
///
/// All measurements are centimeters, matching how this app already
/// stores waist/neck/hip. The formula's log terms are only defined for
/// positive arguments, so a measurement combination outside the
/// formula's valid domain (e.g. waist not exceeding neck) returns `nil`
/// rather than a nonsensical or NaN result.
enum NavyBodyFatCalculator {
    static func estimate(
        sex: BiologicalSex,
        heightCm: Double,
        waistCm: Double,
        neckCm: Double,
        hipCm: Double?
    ) -> Double? {
        guard heightCm > 0 else { return nil }

        switch sex {
        case .male:
            let circumferenceDifference = waistCm - neckCm

            guard circumferenceDifference > 0 else { return nil }

            let denominator = 1.0324
                - 0.19077 * log10(circumferenceDifference)
                + 0.15456 * log10(heightCm)

            guard denominator > 0 else { return nil }

            return 495 / denominator - 450

        case .female:
            guard let hipCm else { return nil }

            let circumferenceSum = waistCm + hipCm - neckCm

            guard circumferenceSum > 0 else { return nil }

            let denominator = 1.29579
                - 0.35004 * log10(circumferenceSum)
                + 0.22100 * log10(heightCm)

            guard denominator > 0 else { return nil }

            return 495 / denominator - 450
        }
    }

    /// Merges actual HealthKit body-fat-% readings with Navy-estimated
    /// values computed from that same calendar day's waist/neck(/hip)
    /// measurements, wherever an actual reading is missing for that day.
    /// An actual reading is never overridden by an estimate — this is
    /// strictly a gap-filler.
    static func fillGaps(
        actual: [DatedValue],
        waist: [DatedValue],
        neck: [DatedValue],
        hip: [DatedValue],
        sex: BiologicalSex?,
        heightCm: Double?
    ) -> [DatedValue] {
        guard let sex, let heightCm else { return actual }

        let calendar = Calendar.current
        let actualDays = Set(actual.map { calendar.startOfDay(for: $0.date) })

        let waistByDay = latestPerDay(waist, calendar: calendar)
        let neckByDay = latestPerDay(neck, calendar: calendar)
        let hipByDay = latestPerDay(hip, calendar: calendar)

        let candidateDays = Set(waistByDay.keys)
            .intersection(neckByDay.keys)
            .subtracting(actualDays)

        var result = actual

        for day in candidateDays.sorted() {
            guard let waistValue = waistByDay[day], let neckValue = neckByDay[day] else { continue }

            guard let estimate = estimate(
                sex: sex,
                heightCm: heightCm,
                waistCm: waistValue,
                neckCm: neckValue,
                hipCm: hipByDay[day]
            ) else { continue }

            result.append(DatedValue(date: day, value: estimate))
        }

        return result
    }

    private static func latestPerDay(
        _ samples: [DatedValue],
        calendar: Calendar
    ) -> [Date: Double] {
        var result: [Date: Double] = [:]

        for sample in samples.sorted(by: { $0.date < $1.date }) {
            result[calendar.startOfDay(for: sample.date)] = sample.value
        }

        return result
    }
}
