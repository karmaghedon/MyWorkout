import SwiftUI

struct ExerciseLibraryView: View {
    let exercises = SeedData.exercises

    var body: some View {
        List(exercises) { exercise in
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline)

                Text(exercise.muscleGroup)
                    .font(.subheadline)

                Text(exercise.equipment)
                    .font(.caption)

                Text(exercise.instructions)
                    .font(.body)
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("Exercise Library")
    }
}
