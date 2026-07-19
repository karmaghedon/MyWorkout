import SwiftUI

struct RecentWorkoutsSection: View {
    let logs: [WorkoutLog]

    var body: some View {
        Section {
            ForEach(logs.prefix(5)) { log in
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

                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\(setCount(for: log)) sets")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            Label("Recent Workouts", systemImage: "clock.arrow.circlepath")
        }
    }

    private func setCount(for log: WorkoutLog) -> Int {
        log.completedExercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
}

#Preview {
    List {
        RecentWorkoutsSection(logs: [])
    }
}
