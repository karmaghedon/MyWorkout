import SwiftUI

/// The single "past workouts" screen — replaces what used to be two
/// separate screens (a flat History list and a date-grouped Calendar list)
/// showing the same underlying logs. This keeps the more informative,
/// date-grouped layout with set counts.
struct HistoryView: View {
    @EnvironmentObject var logStore: WorkoutLogStore

    private var groupedLogs: [(date: Date, logs: [WorkoutLog])] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: logStore.logs) { log in
            calendar.startOfDay(for: log.date)
        }

        return grouped
            .map { (date: $0.key, logs: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            ForEach(groupedLogs, id: \.date) { group in
                Section(group.date.formatted(date: .long, time: .omitted)) {
                    ForEach(group.logs) { log in
                        NavigationLink {
                            WorkoutLogDetailView(log: log)
                        } label: {
                            HStack(spacing: AppTheme.Spacing.md) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppTheme.accentMuted)

                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .frame(width: 44, height: 44)
                                .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.workoutName)
                                        .font(.headline)

                                    Text(log.date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text("\(setCount(for: log)) sets")
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .overlay {
            if logStore.logs.isEmpty {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Workouts Yet")
                .font(.headline)

            Text("Finish a workout and it'll show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }

    private func setCount(for log: WorkoutLog) -> Int {
        log.completedExercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
}
