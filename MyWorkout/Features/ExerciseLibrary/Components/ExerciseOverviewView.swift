import SwiftUI

struct ExerciseOverviewView: View {
    let exercise: Exercise

    var body: some View {
        Section("Overview") {
            InfoRow(title: "Muscle Group", value: exercise.muscleGroup.displayName)
            InfoRow(
                title: "Equipment",
                value: exercise.equipment.displayName
            )
            InfoRow(title: "Difficulty", value: exercise.difficulty)
            InfoRow(title: "Type", value: exercise.exerciseType.rawValue.capitalized)
            InfoRow(title: "Progression", value: exercise.progressionStrategy.rawValue.capitalized)
        }
    }
}
