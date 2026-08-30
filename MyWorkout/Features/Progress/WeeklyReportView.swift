import SwiftUI

/// Newest-first weekly weight/body-fat-%/waist/neck cards, computed from
/// HealthKit samples plus local neck/hip logs — see
/// `WeeklyBodyReportEngine` for the windowing algorithm. Weight respects
/// `UserSettings.bodyWeightUnitSystem` (lb/kg) — separate from the
/// training-weight unit — waist and neck stay in centimeters, same as
/// `LogWeightView`. Body fat % is whichever HealthKit reading or
/// `NavyBodyFatCalculator` estimate `WeeklyBodyReportStore` resolved for
/// that window — this view has no way to tell which one it is.
struct WeeklyReportView: View {
    @EnvironmentObject private var weeklyBodyReportStore: WeeklyBodyReportStore
    @EnvironmentObject private var bodyMeasurementLogStore: BodyMeasurementLogStore
    @EnvironmentObject private var settingsStore: UserSettingsStore

    var body: some View {
        ScrollView {
            content
                .padding(.vertical)
        }
        .navigationTitle("Weekly Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await weeklyBodyReportStore.reload(
                bodyMeasurementLogs: bodyMeasurementLogStore.logs,
                sex: settingsStore.settings.biologicalSex,
                heightCm: settingsStore.settings.heightCm
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if weeklyBodyReportStore.isLoading && weeklyBodyReportStore.cards.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.Spacing.xl)
        } else if let loadError = weeklyBodyReportStore.loadError {
            Text(loadError)
                .foregroundStyle(AppTheme.warning)
                .padding(.horizontal)
        } else if weeklyBodyReportStore.cards.isEmpty {
            AppEmptyStateView(
                title: "No Weigh-Ins Yet",
                message: "Log a weigh-in to start building your weekly report.",
                systemImage: "calendar"
            )
        } else {
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(weeklyBodyReportStore.cards.reversed()) { card in
                    weeklyCard(card)
                        .padding(.horizontal)
                }
            }
        }
    }

    private func weeklyCard(_ card: WeeklyBodyReportCard) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(weekRangeText(card))
                    .font(AppTheme.Typography.cardTitle)

                metricRow(
                    label: "Weight",
                    value: weightRangeText(card),
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

    private func weekRangeText(_ card: WeeklyBodyReportCard) -> String {
        let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: card.windowEnd) ?? card.windowEnd

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return "\(formatter.string(from: card.windowStart)) – \(formatter.string(from: lastDay))"
    }

    private func weightRangeText(_ card: WeeklyBodyReportCard) -> String {
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
