import SwiftUI

struct WorkoutExerciseListView: View {
    let exercises: [Exercise]
    let stateForExercise: (UUID) -> Binding<ExerciseSessionState>
    let previousSetsForExercise: (Exercise) -> [LoggedSet]
    let weightStepForExercise: (Exercise) -> Int
    let equipmentInventory: EquipmentInventory

    let activeRestExerciseID: UUID?
    let restSecondsRemaining: Int
    let restTotalSeconds: Int

    let onLogSet: (Exercise) -> Void
    let onStopRest: () -> Void
    let onDeleteSet: (UUID, Exercise) -> Void

    var body: some View {
        ForEach(exercises) { exercise in
            ExerciseSessionCardView(
                exercise: exercise,
                state: stateForExercise(exercise.id),
                previousSets: previousSetsForExercise(exercise),
                weightStep: weightStepForExercise(exercise),
                equipmentInventory: equipmentInventory,
                isResting: activeRestExerciseID == exercise.id && restSecondsRemaining > 0,
                restSecondsRemaining: restSecondsRemaining,
                restTotalSeconds: restTotalSeconds,
                onLogSet: {
                    onLogSet(exercise)
                },
                onStopRest: onStopRest,
                onDeleteSet: { setID in
                    onDeleteSet(setID, exercise)
                }
            )
        }
    }
}
