import SwiftUI

struct RecentWorkoutsSection: View {
    let logs: [WorkoutLog]

    var body: some View {
        Section {
            ForEach(logs.prefix(5)) { log in
                NavigationLink {
                    WorkoutLogDetailView(log: log)
                } label: {
                    WorkoutCard(
                        systemImage: "checkmark.seal.fill",
                        title: log.workoutName
                    ) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.secondaryText)

                            Text("\(setCount(for: log)) sets")
                                .font(AppTheme.Typography.caption)
                        }
                    }
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
