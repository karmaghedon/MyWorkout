import SwiftUI

struct ExerciseInstructionsView: View {
    let exercise: Exercise

    var body: some View {
        Section("Instructions") {
            Text(exercise.instructions.isEmpty ? "No instructions available yet." : exercise.instructions)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    List {
        ExerciseInstructionsView(exercise: SeedData.exercises.first!)
    }
}
