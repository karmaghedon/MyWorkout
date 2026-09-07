import SwiftUI

struct ExerciseWarningsView: View {
    let exercise: Exercise

    var body: some View {
        if !exercise.commonMistakes.isEmpty {
            Section("Common Mistakes") {
                ForEach(exercise.commonMistakes, id: \.self) { mistake in
                    Label(mistake, systemImage: "exclamationmark.triangle")
                }
            }
        }

        if !exercise.warnings.isEmpty {
            Section("Safety") {
                ForEach(exercise.warnings, id: \.self) { warning in
                    Label(warning, systemImage: "shield")
                }
            }
        }
    }
}

#Preview {
    List {
        ExerciseWarningsView(exercise: SeedData.exercises.first!)
    }
}
