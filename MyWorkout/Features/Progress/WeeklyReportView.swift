import SwiftUI

/// The top-level "weekly body report" screen. Used to stack every
/// weekly card (weight/body-fat-%/waist/neck) in one continuously
/// growing scroll — for anyone with more than a few months of
/// weigh-ins that became one very long list with no structure above
/// the week level. Grouping by month and drilling into
/// `MonthlyBodyReportView` for the week-by-week cards turns that into
/// genuinely separate, naturally-bounded pages instead — same approach
/// as `HistoryView`'s month drill-down for workouts.
///
/// See `WeeklyBodyReportEngine` for the windowing algorithm and
/// `WeeklyBodyReportCardView` for how an individual week's card reads
/// its values.
struct WeeklyReportView: View {
    @EnvironmentObject private var weeklyBodyReportStore: WeeklyBodyReportStore
    @EnvironmentObject private var bodyMeasurementLogStore: BodyMeasurementLogStore
    @EnvironmentObject private var settingsStore: UserSettingsStore

    private struct MonthGroup: Identifiable {
        let monthStart: Date
        let cards: [WeeklyBodyReportCard]

        var id: Date { monthStart }
    }

    private var monthGroups: [MonthGroup] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: weeklyBodyReportStore.cards) { card in
            calendar.dateInterval(of: .month, for: card.windowStart)?.start ?? card.windowStart
        }

        return grouped
            .map { monthStart, cards in
                MonthGroup(
                    monthStart: monthStart,
                    cards: cards.sorted { $0.windowStart > $1.windowStart }
                )
            }
            .sorted { $0.monthStart > $1.monthStart }
    }

    var body: some View {
        content
            .navigationTitle("Weekly Report")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Not `.task`: this screen's tab keeps its NavigationStack
                // mounted across tab switches, so `.task` (tied to view
                // identity, fires once per lifetime) would never reload
                // after logging a new weigh-in/measurement elsewhere and
                // returning here. `.onAppear` fires every time this becomes
                // visible again.
                Task {
                    await weeklyBodyReportStore.reload(
                        bodyMeasurementLogs: bodyMeasurementLogStore.logs,
                        sex: settingsStore.settings.biologicalSex,
                        heightCm: settingsStore.settings.heightCm
                    )
                }
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
            ScrollView {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(monthGroups) { group in
                        monthRow(group)
                    }
                }
                .padding(.vertical)
            }
        }
    }

    private func monthRow(_ group: MonthGroup) -> some View {
        NavigationLink {
            MonthlyBodyReportView(monthStart: group.monthStart, cards: group.cards)
        } label: {
            AppCard {
                HStack {
                    Text(group.monthStart.formatted(.dateTime.month(.wide).year()))
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(Color.primary)

                    Spacer()

                    Text("\(group.cards.count) week\(group.cards.count == 1 ? "" : "s")")
                        .font(AppTheme.Typography.label)
                        .foregroundStyle(AppTheme.secondaryText)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}
