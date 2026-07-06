import SwiftUI

struct ExerciseOverviewView: View {
    let exercise: Exercise

    var body: some View {
        Section("Overview") {
            DetailRow(title: "Muscle Group", value: exercise.muscleGroup)
            DetailRow(title: "Equipment", value: exercise.equipment)
            DetailRow(title: "Difficulty", value: exercise.difficulty)
            DetailRow(title: "Type", value: exercise.exerciseType.rawValue.capitalized)
            DetailRow(title: "Progression", value: exercise.progressionStrategy.rawValue.capitalized)
        }
    }
}
