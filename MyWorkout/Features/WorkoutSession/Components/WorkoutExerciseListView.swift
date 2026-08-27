import SwiftUI

struct WorkoutExerciseListView: View {
    let exercises: [Exercise]
    let layout: WorkoutSessionLayout
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
    let onToggleWarmup: (Exercise, Int, Double, Int) -> Void
    let onUpdateWarmupSet: (Exercise, Int, Double, Int, [WarmupSet]) -> Void
    let onAddWarmupSet: (Exercise, [WarmupSet]) -> Void
    let onRemoveWarmupSet: (Exercise, Int, [WarmupSet]) -> Void
    let onAddSet: (Exercise) -> Void
    let onRemoveSet: (Exercise) -> Void

    /// All exercises' current state, gathered fresh per render — needed to
    /// decide whether a superset member is allowed to log its next set
    /// (that depends on its *siblings'* progress, not just its own).
    private var statesByExerciseID: [UUID: ExerciseSessionState] {
        Dictionary(
            uniqueKeysWithValues: exercises.map { ($0.id, stateForExercise($0.id).wrappedValue) }
        )
    }

    var body: some View {
        let states = statesByExerciseID

        ForEach(exercises) { exercise in
            let isResting = activeRestExerciseID == exercise.id && restSecondsRemaining > 0
            let canLogNextSet = WorkoutSessionEngine.canLogNextSet(
                for: exercise,
                in: exercises,
                states: states
            )
            let nextSupersetExerciseName = WorkoutSessionEngine.nextSupersetExercise(
                after: exercise,
                in: exercises,
                states: states
            )?.name

            Group {
                switch layout {
                case .classic:
                    ExerciseSessionCardView(
                        exercise: exercise,
                        state: stateForExercise(exercise.id),
                        previousSets: previousSetsForExercise(exercise),
                        weightStep: weightStepForExercise(exercise),
                        equipmentInventory: equipmentInventory,
                        isResting: isResting,
                        restSecondsRemaining: restSecondsRemaining,
                        restTotalSeconds: restTotalSeconds,
                        canLogNextSet: canLogNextSet,
                        nextSupersetExerciseName: nextSupersetExerciseName,
                        onLogSet: {
                            onLogSet(exercise)
                        },
                        onStopRest: onStopRest,
                        onDeleteSet: { setID in
                            onDeleteSet(setID, exercise)
                        }
                    )

                case .checklist:
                    ChecklistExerciseSessionCardView(
                        exercise: exercise,
                        state: stateForExercise(exercise.id),
                        previousSets: previousSetsForExercise(exercise),
                        weightStep: weightStepForExercise(exercise),
                        equipmentInventory: equipmentInventory,
                        isResting: isResting,
                        restSecondsRemaining: restSecondsRemaining,
                        restTotalSeconds: restTotalSeconds,
                        canLogNextSet: canLogNextSet,
                        nextSupersetExerciseName: nextSupersetExerciseName,
                        onLogSet: {
                            onLogSet(exercise)
                        },
                        onStopRest: onStopRest,
                        onDeleteSet: { setID in
                            onDeleteSet(setID, exercise)
                        },
                        onToggleWarmup: { index, weight, reps in
                            onToggleWarmup(exercise, index, weight, reps)
                        },
                        onUpdateWarmupSet: { index, weight, reps, currentWarmups in
                            onUpdateWarmupSet(exercise, index, weight, reps, currentWarmups)
                        },
                        onAddWarmupSet: { currentWarmups in
                            onAddWarmupSet(exercise, currentWarmups)
                        },
                        onRemoveWarmupSet: { index, currentWarmups in
                            onRemoveWarmupSet(exercise, index, currentWarmups)
                        },
                        onAddSet: {
                            onAddSet(exercise)
                        },
                        onRemoveSet: {
                            onRemoveSet(exercise)
                        }
                    )
                }
            }
            .superset(exercise.supersetGroupID)
            .id(exercise.id)
        }
    }
}

private extension View {
    /// Visual indicator that this exercise card is part of a superset —
    /// a colored leading bar, matching the same treatment
    /// `TemplateExercisesSection` uses so the grouping reads consistently
    /// between editing a template and actually running the workout.
    @ViewBuilder
    func superset(_ groupID: UUID?) -> some View {
        if groupID != nil {
            self
                .padding(.leading, AppTheme.Spacing.sm)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.accent)
                        .frame(width: 3)
                }
        } else {
            self
        }
    }
}
