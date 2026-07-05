import SwiftUI

struct WorkoutSessionContentView: View {
    let workout: Workout

    let elapsedTime: String

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

    let onFinish: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.lg) {
                WorkoutTimerCardView(
                    elapsedTime: elapsedTime
                )

                WorkoutExerciseListView(
                    exercises: workout.exercises,
                    stateForExercise: stateForExercise,
                    previousSetsForExercise: previousSetsForExercise,
                    weightStepForExercise: weightStepForExercise,
                    equipmentInventory: equipmentInventory,
                    activeRestExerciseID: activeRestExerciseID,
                    restSecondsRemaining: restSecondsRemaining,
                    restTotalSeconds: restTotalSeconds,
                    onLogSet: onLogSet,
                    onStopRest: onStopRest,
                    onDeleteSet: onDeleteSet
                )

                WorkoutSessionActionsView(
                    onFinish: onFinish,
                    onCancel: onCancel
                )
            }
            .padding(AppTheme.Spacing.lg)
            .animation(.default, value: activeRestExerciseID)
        }
    }
}
