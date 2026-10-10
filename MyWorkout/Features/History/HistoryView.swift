import SwiftUI

/// The top-level "past workouts" screen. Used to list every day that
/// ever had a workout in one continuously growing, manually-paginated
/// list ("Load More") — for anyone with more than a few months of
/// history that became one very long scroll with no real structure
/// above the day level. Grouping by month and drilling into
/// `MonthHistoryView` for the day-by-day breakdown turns that into
/// genuinely separate, naturally-bounded pages instead.
struct HistoryView: View {
    @EnvironmentObject var logStore: WorkoutLogStore

    @State private var monthGroups: [MonthGroup] = []

    private struct MonthGroup: Identifiable {
        let monthStart: Date
        let logs: [WorkoutLog]

        var id: Date { monthStart }

        var totalSets: Int {
            logs.reduce(0) { total, log in
                total + log.completedExercises.reduce(0) { $0 + $1.sets.count }
            }
        }
    }

    var body: some View {
        List {
            ForEach(monthGroups) { group in
                NavigationLink {
                    MonthHistoryView(monthStart: group.monthStart, logs: group.logs)
                } label: {
                    HStack {
                        Text(group.monthStart.formatted(.dateTime.month(.wide).year()))

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(group.logs.count) workout\(group.logs.count == 1 ? "" : "s")")

                            Text("\(group.totalSets) sets")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .overlay {
            if logStore.logs.isEmpty {
                AppEmptyStateView(
                    title: "No Workouts Yet",
                    message: "Finish a workout and it'll show up here.",
                    systemImage: "clock.arrow.circlepath"
                )
            }
        }
        .onAppear {
            regroup()
        }
        .onChange(of: logStore.logs.count) { _, _ in
            regroup()
        }
    }

    private func regroup() {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: logStore.logs) { log in
            calendar.dateInterval(of: .month, for: log.date)?.start ?? log.date
        }

        monthGroups = grouped
            .map { MonthGroup(monthStart: $0.key, logs: $0.value) }
            .sorted { $0.monthStart > $1.monthStart }
    }
}
