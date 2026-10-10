import SwiftUI

/// One week's weight/body-fat-%/waist/neck summary card — extracted out
/// of `WeeklyReportView` so `MonthlyBodyReportView` (the month
/// drill-down page `WeeklyReportView` now pushes into) can render the
/// exact same card without duplicating the formatting logic. Weight
/// respects `UserSettings.bodyWeightUnitSystem` (lb/kg) — separate from
/// the training-weight unit — waist and neck stay in centimeters, same
/// as `LogWeightView`.
struct WeeklyBodyReportCardView: View {
    let card: WeeklyBodyReportCard

    @EnvironmentObject private var settingsStore: UserSettingsStore

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text(weekRangeText)
                        .font(AppTheme.Typography.cardTitle)

                    Spacer()

                    NavigationLink(
                        value: AppRoute.measurementHistoryForWeek(
                            start: card.windowStart,
                            end: card.windowEnd
                        )
                    ) {
                        Image(systemName: "pencil.circle")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                metricRow(
                    label: "Weight",
                    value: weightRangeText,
                    delta: card.weightAvgDelta.map { displayWeightDelta($0) }
                )

                if let bodyFatLatest = card.bodyFatPercentLatest {
                    metricRow(
                        label: "Fat %",
                        value: "\(formatWeight(bodyFatLatest)) %",
                        delta: card.bodyFatPercentDelta.map { deltaText($0, unit: "%") }
                    )
                }

                if let waistLatest = card.waistLatest {
                    metricRow(
                        label: "Waist",
                        value: "\(formatWeight(waistLatest)) cm",
                        delta: card.waistDelta.map { deltaText($0, unit: "cm") }
                    )
                }

                if let neckLatest = card.neckLatest {
                    metricRow(
                        label: "Neck",
                        value: "\(formatWeight(neckLatest)) cm",
                        delta: card.neckDelta.map { deltaText($0, unit: "cm") }
                    )
                }
            }
        }
    }

    private func metricRow(label: String, value: String, delta: String?) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 56, alignment: .leading)

            Text(value)
                .font(AppTheme.Typography.label)

            Spacer()

            if let delta {
                Text(delta)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    // MARK: - Formatting

    private var weekRangeText: String {
        let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: card.windowEnd) ?? card.windowEnd

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return "\(formatter.string(from: card.windowStart)) – \(formatter.string(from: lastDay))"
    }

    private var weightRangeText: String {
        let unit = settingsStore.settings.bodyWeightUnitSystem.rawValue
        let avg = displayWeight(kg: card.weightAvg)

        guard card.weightMin != card.weightMax else {
            return "\(formatWeight(avg)) \(unit)"
        }

        let min = displayWeight(kg: card.weightMin)
        let max = displayWeight(kg: card.weightMax)

        return "\(formatWeight(avg)) \(unit) avg (\(formatWeight(min))–\(formatWeight(max)))"
    }

    private func displayWeightDelta(_ deltaKg: Double) -> String {
        let pounds = WeightConversion.kilogramsToPounds(deltaKg)
        let display = WeightConversion.fromPounds(pounds, to: settingsStore.settings.bodyWeightUnitSystem)

        return deltaText(display, unit: settingsStore.settings.bodyWeightUnitSystem.rawValue)
    }

    private func displayWeight(kg: Double) -> Double {
        let pounds = WeightConversion.kilogramsToPounds(kg)
        return WeightConversion.fromPounds(pounds, to: settingsStore.settings.bodyWeightUnitSystem)
    }

    private func deltaText(_ delta: Double, unit: String) -> String {
        let magnitude = formatWeight(abs(delta))

        if delta > 0 {
            return "▲ \(magnitude) \(unit)"
        } else if delta < 0 {
            return "▼ \(magnitude) \(unit)"
        } else {
            return "– 0 \(unit)"
        }
    }
}
