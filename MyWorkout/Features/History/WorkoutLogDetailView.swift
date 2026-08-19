import SwiftUI

struct WorkoutLogDetailView: View {
    let log: WorkoutLog

    @EnvironmentObject var settingsStore: UserSettingsStore

    var body: some View {
        List {
            Section("Summary") {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }

                if let durationSeconds = log.durationSeconds {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(ActiveWorkoutStore.formatDuration(durationSeconds))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ForEach(log.completedExercises) { exercise in
                Section(exercise.exerciseName) {
                    ForEach(exercise.sets) { set in
                        Text("Set \(set.setNumber): \(formatWeight(settingsStore.settings.displayWeight(set.weight))) \(settingsStore.settings.weightUnitLabel) × \(set.reps)")
                    }

                    if !exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(AppTheme.Typography.caption)
                                .bold()

                            Text(exercise.notes)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 6)
                    }
                }
            }
        }
        .navigationTitle(log.workoutName)
    }
}
