import SwiftUI

/// One month's workouts, day-grouped — reached by drilling into a month
/// row on `HistoryView`. Naturally bounded (at most a month's worth of
/// entries), so unlike the old flat list this never needs its own
/// pagination.
struct MonthHistoryView: View {
    let monthStart: Date
    let logs: [WorkoutLog]

    private var groupedByDay: [(date: Date, logs: [WorkoutLog])] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.date)
        }

        return grouped
            .map { (date: $0.key, logs: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            ForEach(groupedByDay, id: \.date) { group in
                Section(group.date.formatted(date: .long, time: .omitted)) {
                    ForEach(group.logs) { log in
                        NavigationLink {
                            WorkoutLogDetailView(log: log)
                        } label: {
                            WorkoutCard(
                                systemImage: "checkmark.seal.fill",
                                title: log.workoutName
                            ) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.date.formatted(date: .omitted, time: .shortened))
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.secondaryText)

                                    Text("\(setCount(for: log)) sets")
                                        .font(AppTheme.Typography.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(monthStart.formatted(.dateTime.month(.wide).year()))
    }

    private func setCount(for log: WorkoutLog) -> Int {
        log.completedExercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
}
