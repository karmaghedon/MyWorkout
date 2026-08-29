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
    let onToggleWarmup: (Exercise, Int, Double, Int) -> Void
    let onUpdateWarmupSet: (Exercise, Int, Double, Int, [WarmupSet]) -> Void
    let onAddWarmupSet: (Exercise, [WarmupSet]) -> Void
    let onRemoveWarmupSet: (Exercise, Int, [WarmupSet]) -> Void
    let onAddSet: (Exercise) -> Void
    let onRemoveSet: (Exercise) -> Void

    let onFinish: () -> Void
    let onCancel: () -> Void

    /// Stable anchor id for "no better place to be" — scrolling here reads
    /// as "top of screen" without needing a scroll-to-offset API.
    private static let topAnchorID = "workoutSessionTop"

    private struct ScrollTarget: Equatable {
        let id: AnyHashable
        let anchor: UnitPoint
    }

    /// Where the view should be scrolled to, in priority order:
    /// 1. The resting exercise's rest timer badge, if one is actually
    ///    counting down.
    /// 2. The superset partner who should act next, if logging a set just
    ///    left some grouped exercise blocked waiting on a sibling — without
    ///    this, finishing a set inside a superset left the user to scroll
    ///    and hunt for whichever exercise became available.
    /// 3. The last exercise with at least one logged set (where the user
    ///    last left off).
    /// 4. The top of the screen, for a fresh, untouched session.
    ///
    /// Case 4 anchors to `.top` rather than `.center` — centering the
    /// header would leave a gap above it instead of pinning it to the top
    /// edge.
    ///
    /// The resting case (1) scrolls to the *badge's* id
    /// (`RestTimerBadge.scrollAnchorID`), not the exercise card's — the
    /// card can be much taller than the screen (warm-ups, several logged
    /// sets, notes), so centering the whole card doesn't put the badge,
    /// which can sit well down the card, anywhere near the center of the
    /// viewport.
    private var scrollTarget: ScrollTarget {
        if let activeRestExerciseID, restSecondsRemaining > 0 {
            return ScrollTarget(
                id: RestTimerBadge.scrollAnchorID(for: activeRestExerciseID),
                anchor: .center
            )
        }

        if let nextActiveSupersetExercise {
            return ScrollTarget(id: nextActiveSupersetExercise.id, anchor: .center)
        }

        if let lastCheckedExerciseID = workout.exercises.last(where: { exercise in
            !stateForExercise(exercise.id).wrappedValue.loggedSets.isEmpty
        })?.id {
            return ScrollTarget(id: lastCheckedExerciseID, anchor: .center)
        }

        return ScrollTarget(id: Self.topAnchorID, anchor: .top)
    }

    /// The superset partner currently "up" — the exercise some blocked
    /// group member is waiting on, per
    /// `WorkoutSessionEngine.nextSupersetExercise`. `nil` whenever nothing
    /// in the workout is currently blocked (no superset in progress, or a
    /// round just tied and either member could go next).
    private var nextActiveSupersetExercise: Exercise? {
        let states = Dictionary(
            uniqueKeysWithValues: workout.exercises.map {
                ($0.id, stateForExercise($0.id).wrappedValue)
            }
        )

        for exercise in workout.exercises {
            guard exercise.supersetGroupID != nil,
                  !WorkoutSessionEngine.canLogNextSet(
                      for: exercise,
                      in: workout.exercises,
                      states: states
                  ),
                  let next = WorkoutSessionEngine.nextSupersetExercise(
                      after: exercise,
                      in: workout.exercises,
                      states: states
                  )
            else { continue }

            return next
        }

        return nil
    }

    var body: some View {
        ScrollViewReader { proxy in
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
                            onUpdateWarmupSet: onUpdateWarmupSet,
                            onAddWarmupSet: onAddWarmupSet,
                            onRemoveWarmupSet: onRemoveWarmupSet,
                            onAddSet: onAddSet,
                            onRemoveSet: onRemoveSet
                        )
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        WorkoutSessionActionsView(
                            onFinish: onFinish,
                            onCancel: onCancel
                        )
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    } header: {
                        CompactWorkoutTimerBar(elapsedTime: elapsedTime)
                            .id(Self.topAnchorID)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.lg)
                .animation(.default, value: activeRestExerciseID)
            }
            .onAppear {
                proxy.scrollTo(scrollTarget.id, anchor: scrollTarget.anchor)
            }
            .onChange(of: scrollTarget) { _, newTarget in
                withAnimation {
                    proxy.scrollTo(newTarget.id, anchor: newTarget.anchor)
                }
            }
        }
    }
}
