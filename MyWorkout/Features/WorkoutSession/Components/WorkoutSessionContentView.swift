import SwiftUI

struct WorkoutSessionContentView: View {
    let workout: Workout
    let layout: WorkoutSessionLayout

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
    let onToggleWarmup: (Exercise, Double, Int) -> Void
    let onAddSet: (Exercise) -> Void

    let onFinish: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                Section {
                    WorkoutExerciseListView(
                        exercises: workout.exercises,
                        layout: layout,
                        stateForExercise: stateForExercise,
                        previousSetsForExercise: previousSetsForExercise,
                        weightStepForExercise: weightStepForExercise,
                        equipmentInventory: equipmentInventory,
                        activeRestExerciseID: activeRestExerciseID,
                        restSecondsRemaining: restSecondsRemaining,
                        restTotalSeconds: restTotalSeconds,
                        onLogSet: onLogSet,
                        onStopRest: onStopRest,
                        onDeleteSet: onDeleteSet,
                        onToggleWarmup: onToggleWarmup,
                        onAddSet: onAddSet
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    WorkoutSessionActionsView(
                        onFinish: onFinish,
                        onCancel: onCancel
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                } header: {
                    CompactWorkoutTimerBar(elapsedTime: elapsedTime)
                }
            }
            .padding(.bottom, AppTheme.Spacing.lg)
            .animation(.default, value: activeRestExerciseID)
        }
    }
}
