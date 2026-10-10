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
    let lastLoggedExerciseID: UUID?

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
    /// Cases 2–4 all anchor to `.top` rather than `.center` — centering a
    /// header-like element would leave a gap above it instead of pinning
    /// it to the top edge.
    ///
    /// Cases 1–3 scroll to a specific sub-element's id
    /// (`RestTimerBadge.scrollAnchorID` / `ExerciseSessionHeaderView.scrollAnchorID`),
    /// not the exercise card's own id — the card can be much taller than
    /// the screen (warm-ups, several logged sets, notes), so scrolling to
    /// the whole card doesn't reliably put any specific part of it (the
    /// rest badge, or the header showing the exercise name and current
    /// set number) anywhere near the viewport. This used to only apply to
    /// the rest badge; the header had the exact same problem once a
    /// card grew tall enough — the name/set-number row would scroll off
    /// the top while the card's geometric center (mid-way through a long
    /// list of warm-ups and logged sets) sat in view instead.
    private var scrollTarget: ScrollTarget {
        if let activeRestExerciseID, restSecondsRemaining > 0 {
            return ScrollTarget(
                id: RestTimerBadge.scrollAnchorID(for: activeRestExerciseID),
                anchor: .center
            )
        }

        if let nextActiveSupersetExercise {
            return ScrollTarget(
                id: ExerciseSessionHeaderView.scrollAnchorID(for: nextActiveSupersetExercise.id),
                anchor: .top
            )
        }

        if let lastCheckedExerciseID = workout.exercises.last(where: { exercise in
            !stateForExercise(exercise.id).wrappedValue.loggedSets.isEmpty
        })?.id {
            return ScrollTarget(
                id: ExerciseSessionHeaderView.scrollAnchorID(for: lastCheckedExerciseID),
                anchor: .top
            )
        }

        return ScrollTarget(id: Self.topAnchorID, anchor: .top)
    }

    /// The superset partner currently "up" — but only when the exercise
    /// blocked waiting on that partner is the one the user was just
    /// working on (`lastLoggedExerciseID`), per
    /// `WorkoutSessionEngine.nextSupersetExercise`. Scoped this way
    /// rather than scanning every exercise in the workout: a superset
    /// elsewhere can sit "mid-rotation" (one member blocked on the other)
    /// for most of the time between its own rounds, so an unscoped scan
    /// would hijack the scroll position to that unrelated superset the
    /// moment rest ends on a completely different exercise. `nil` when
    /// the last-logged exercise isn't grouped, or isn't currently
    /// blocked (no superset in progress, or a round just tied and either
    /// member could go next).
    private var nextActiveSupersetExercise: Exercise? {
        guard let lastLoggedExerciseID,
              let exercise = workout.exercises.first(where: { $0.id == lastLoggedExerciseID }),
              exercise.supersetGroupID != nil
        else { return nil }

        let states = Dictionary(
            uniqueKeysWithValues: workout.exercises.map {
                ($0.id, stateForExercise($0.id).wrappedValue)
            }
        )

        guard !WorkoutSessionEngine.canLogNextSet(
            for: exercise,
            in: workout.exercises,
            states: states
        ) else { return nil }

        return WorkoutSessionEngine.nextSupersetExercise(
            after: exercise,
            in: workout.exercises,
            states: states
        )
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
