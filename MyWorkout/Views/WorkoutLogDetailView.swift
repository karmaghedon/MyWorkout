import SwiftUI

struct WorkoutLogDetailView: View {
    let log: WorkoutLog

    var body: some View {
        List {
            ForEach(log.completedExercises) { exercise in
                Section(exercise.exerciseName) {
                    ForEach(exercise.sets) { set in
                        Text("Set \(set.setNumber): \(set.weight) lb × \(set.reps)")
                    }

                    if !exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .bold()

                            Text(exercise.notes)
                                .font(.caption)
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
