import SwiftUI
import Foundation

@MainActor
final class ActiveWorkoutStore: ObservableObject {
    @Published var activeWorkout: Workout? {
        didSet { schedulePersist() }
    }

    @Published var exerciseStates: [UUID: ExerciseSessionState] = [:] {
        didSet { schedulePersist() }
    }

    @Published var startedAt: Date? {
        didSet { schedulePersist() }
    }

    @Published var elapsedSeconds: Int = 0

    @Published private(set) var restTimerState: RestTimerState? {
        didSet { schedulePersist() }
    }

    @Published private(set) var restSecondsRemaining: Int = 0
    @Published private(set) var persistenceError: StoreError?

    private let persistenceCoordinator:
        ActiveWorkoutPersistenceCoordinator

    private var workoutTimer: Timer?
    private var isRestoring = false
    private var restTimer: Timer?

    init(
        persistence: any ActiveWorkoutPersisting =
            FileActiveWorkoutPersistence()
    ) {
        persistenceCoordinator =
            ActiveWorkoutPersistenceCoordinator(
                persistence: persistence
            )

        restoreActiveWorkout()
    }

    var hasActiveWorkout: Bool {
        activeWorkout != nil
    }

    var hasLoggedSets: Bool {
        exerciseStates.values.contains {
            !$0.loggedSets.isEmpty
        }
    }

    var formattedElapsedTime: String {
        Self.formatDuration(elapsedSeconds)
    }

    // MARK: - Rest Timer Compatibility

    var activeRestExerciseID: UUID? {
        restTimerState?.exerciseID
    }

    var restStartedAt: Date? {
        restTimerState?.startedAt
    }

    var restTotalSeconds: Int {
        restTimerState?.durationSeconds ?? 0
    }

    // MARK: - Workout Lifecycle

    @discardableResult
    func start(
        _ workout: Workout
    ) -> WorkoutStartResult {
        guard !hasActiveWorkout else {
            return .activeWorkoutAlreadyExists
        }

        beginWorkout(workout)
        return .started
    }

    func resumeTimer() {
        guard activeWorkout != nil else {
            return
        }

        if startedAt == nil {
            startedAt = Date()
        }

        updateElapsedSeconds()
        startTimerIfNeeded()
    }

    func cancel() {
        stopTimer()
        stopRestTimer(clearPersistedState: true)
        clearActiveWorkout()
    }

    func finish() {
        stopTimer()
        stopRestTimer(clearPersistedState: true)
        clearActiveWorkout()
    }

    func currentDurationSeconds() -> Int {
        guard let startedAt else {
            return elapsedSeconds
        }

        return max(
            0,
            Int(Date().timeIntervalSince(startedAt))
        )
    }

    // MARK: - Exercise State

    func binding(
        for exerciseID: UUID
    ) -> Binding<ExerciseSessionState> {
        Binding(
            get: {
                self.exerciseStates[exerciseID]
                    ?? ExerciseSessionState()
            },
            set: { newState in
                self.exerciseStates[exerciseID] = newState
            }
        )
    }

    func logSet(for exerciseID: UUID) {
        WorkoutSessionEngine.logSet(
            for: exerciseID,
            in: &exerciseStates
        )
    }

    func deleteSet(
        setID: UUID,
        for exerciseID: UUID
    ) {
        WorkoutSessionEngine.deleteSet(
            setID: setID,
            for: exerciseID,
            in: &exerciseStates
        )
    }

    func toggleWarmupComplete(weight: Double, reps: Int, for exerciseID: UUID) {
        var state = exerciseStates[exerciseID] ?? ExerciseSessionState()
        let key = ExerciseSessionState.warmupKey(weight: weight, reps: reps)

        if state.completedWarmupKeys.contains(key) {
            state.completedWarmupKeys.remove(key)
        } else {
            state.completedWarmupKeys.insert(key)
        }

        exerciseStates[exerciseID] = state
    }

    func addExtraSet(for exerciseID: UUID) {
        var state = exerciseStates[exerciseID] ?? ExerciseSessionState()
        state.extraWorkingSets += 1
        exerciseStates[exerciseID] = state
    }

    /// Undoes one tap of `addExtraSet` — e.g. an accidental tap of "Add
    /// Set". Floored at 0 rather than going negative; harmless no-op if
    /// there's nothing extra to remove (the button that calls this is
    /// hidden in that case anyway).
    func removeExtraSet(for exerciseID: UUID) {
        var state = exerciseStates[exerciseID] ?? ExerciseSessionState()
        state.extraWorkingSets = max(0, state.extraWorkingSets - 1)
        exerciseStates[exerciseID] = state
    }

    /// Edits one warm-up set's weight/reps in place, by position rather
    /// than by `WarmupSet.id`. Auto-generated warm-ups (`customWarmups ==
    /// nil`) get a fresh random id every time `warmups` is recomputed —
    /// the view's row and this call each evaluate that computed property
    /// separately, so an id captured by the row would never match the id
    /// in `currentWarmups` by the time this runs. The position is stable
    /// across those separate evaluations because `WarmupEngine.generateWarmups`
    /// is a pure function of the working weight: same input, same
    /// weight/reps in the same order, every time — only the ids differ.
    /// `currentWarmups` is whatever the view is currently displaying —
    /// either that auto-generated ramp or a prior edit — so the very
    /// first edit turns the whole list into an explicit `customWarmups`
    /// override (see its doc comment) rather than just this one set.
    func updateWarmupSet(
        at index: Int,
        weight: Double,
        reps: Int,
        currentWarmups: [WarmupSet],
        for exerciseID: UUID
    ) {
        var state = exerciseStates[exerciseID] ?? ExerciseSessionState()

        var warmups = currentWarmups
        guard warmups.indices.contains(index) else {
            return
        }

        warmups[index].weight = weight
        warmups[index].reps = reps

        state.customWarmups = warmups
        exerciseStates[exerciseID] = state
    }

    /// Appends a new warm-up set, seeded with the last warm-up's
    /// weight/reps (or a light default if there isn't one yet) so it's a
    /// reasonable starting point to then edit rather than starting at 0.
    func addWarmupSet(currentWarmups: [WarmupSet], for exerciseID: UUID) {
        var state = exerciseStates[exerciseID] ?? ExerciseSessionState()

        let last = currentWarmups.last
        let newWarmup = WarmupSet(
            weight: last?.weight ?? 45,
            reps: last?.reps ?? 10
        )

        state.customWarmups = currentWarmups + [newWarmup]
        exerciseStates[exerciseID] = state
    }

    /// Removes one warm-up set by position — e.g. an accidental tap of
    /// "Add Warm-up Set," or a set from the auto-generated ramp the user
    /// doesn't want this session. Same position-not-id reasoning as
    /// `updateWarmupSet`: `currentWarmups` is whatever the view is
    /// currently showing, re-evaluated fresh at call time, so it's safe
    /// to index into directly even though its ids may differ from
    /// whatever the tapped row's `WarmupSet` had.
    func removeWarmupSet(at index: Int, currentWarmups: [WarmupSet], for exerciseID: UUID) {
        var state = exerciseStates[exerciseID] ?? ExerciseSessionState()

        var warmups = currentWarmups
        guard warmups.indices.contains(index) else {
            return
        }

        warmups.remove(at: index)

        state.customWarmups = warmups
        exerciseStates[exerciseID] = state
    }

    func initializeExerciseStates(
        for workout: Workout,
        logStore: WorkoutLogStore,
        equipmentInventory: EquipmentInventory
    ) {
        for exercise in workout.exercises {
            guard exerciseStates[exercise.id] == nil else {
                continue
            }

            let performances = logStore.lastPerformances(
                for: exercise,
                limit: exercise.progressionRule.stallLimit
            )

            exerciseStates[exercise.id] =
                WorkoutSessionEngine.initialState(
                    for: exercise,
                    latestPerformance: performances.first,
                    previousPerformances:
                        Array(performances.dropFirst()),
                    equipmentInventory: equipmentInventory
                )
        }
    }

    // MARK: - Rest Timer

    func startRestTimer(
        for exerciseID: UUID,
        totalSeconds: Int
    ) {
        stopRestTimer(clearPersistedState: false)

        restTimerState = RestTimerState(
            exerciseID: exerciseID,
            durationSeconds: totalSeconds
        )

        restSecondsRemaining =
            restTimerState?.remainingSeconds() ?? 0

        startRestTimerIfNeeded()
        persistActiveWorkout()
    }

    func startRestTimer(
        for exercise: Exercise,
        settings: UserSettings
    ) {
        let seconds = RestTimerRule.seconds(
            for: exercise.exerciseType,
            settings: settings
        )

        startRestTimer(
            for: exercise.id,
            totalSeconds: seconds
        )
    }

    func stopRestTimer(
        clearPersistedState: Bool = true
    ) {
        restTimer?.invalidate()
        restTimer = nil
        restSecondsRemaining = 0

        if clearPersistedState {
            restTimerState = nil
            persistActiveWorkout()
        }
    }

    func restoreRestTimerIfNeeded() {
        updateRestSecondsRemaining()

        if restSecondsRemaining > 0 {
            startRestTimerIfNeeded()
        } else {
            stopRestTimer(clearPersistedState: true)
        }
    }

    func replaceActiveWorkout(
        with workout: Workout
    ) {
        cancel()
        beginWorkout(workout)
    }

    private func startRestTimerIfNeeded() {
        guard restTimer == nil else {
            return
        }

        guard let restTimerState,
              restTimerState.isActive() else {
            return
        }

        restTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            self?.updateRestSecondsRemaining(
                playsCompletionHaptic: true
            )
        }
    }

    private func beginWorkout(
        _ workout: Workout
    ) {
        persistenceCoordinator.cancelScheduledRequest()

        activeWorkout = workout
        exerciseStates = [:]
        startedAt = Date()
        elapsedSeconds = 0

        startTimerIfNeeded()
        persistActiveWorkout()
    }

    /// `playsCompletionHaptic` is only `true` from the live per-second
    /// countdown tick. The restore-on-launch caller passes `false` so
    /// reopening the app after a rest timer already finished in the
    /// background doesn't buzz the phone.
    private func updateRestSecondsRemaining(
        playsCompletionHaptic: Bool = false
    ) {
        guard let restTimerState else {
            restSecondsRemaining = 0
            return
        }

        let remaining =
            restTimerState.remainingSeconds()

        restSecondsRemaining = remaining

        if remaining == 0 {
            stopRestTimer(clearPersistedState: true)

            if playsCompletionHaptic {
                Haptics.restComplete()
            }
        }
    }

    // MARK: - Workout Timer

    private func startTimerIfNeeded() {
        guard workoutTimer == nil else {
            return
        }

        workoutTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            self?.updateElapsedSeconds()
        }
    }

    private func stopTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }

    private func updateElapsedSeconds() {
        elapsedSeconds = currentDurationSeconds()
    }

    // MARK: - Persistence Errors

    func clearPersistenceError() {
        persistenceError = nil
    }

    private func setPersistenceError(
        operation: StoreOperation,
        message: String
    ) {
        persistenceError = StoreError(
            operation: operation,
            message: message
        )
    }

    private func clearPersistenceError(
        for operation: StoreOperation
    ) {
        guard persistenceError?.operation == operation else {
            return
        }

        persistenceError = nil
    }

    // MARK: - Persistence Coordination

    private func schedulePersist() {
        guard !isRestoring else {
            return
        }

        persistenceCoordinator.schedule(
            persistenceRequest(),
            onSuccess: persistenceDidSucceed,
            onFailure: persistenceDidFail
        )
    }

    private func clearActiveWorkout() {
        persistenceCoordinator.cancelScheduledRequest()

        isRestoring = true

        activeWorkout = nil
        exerciseStates = [:]
        startedAt = nil
        elapsedSeconds = 0
        restTimerState = nil
        restSecondsRemaining = 0

        isRestoring = false

        deletePersistedWorkout()
    }

    private func persistActiveWorkout() {
        guard !isRestoring else {
            return
        }

        persistenceCoordinator.perform(
            persistenceRequest(),
            onSuccess: persistenceDidSucceed,
            onFailure: persistenceDidFail
        )
    }

    private func deletePersistedWorkout() {
        persistenceCoordinator.perform(
            .delete,
            onSuccess: persistenceDidSucceed,
            onFailure: persistenceDidFail
        )
    }

    private func persistenceRequest()
        -> ActiveWorkoutPersistenceCoordinator.Request {
        guard let snapshot = activeWorkoutSnapshot() else {
            return .delete
        }

        return .save(snapshot)
    }

    private func activeWorkoutSnapshot()
        -> ActiveWorkoutSnapshot? {
        guard let activeWorkout else {
            return nil
        }

        return ActiveWorkoutSnapshot(
            activeWorkout: activeWorkout,
            exerciseStates: exerciseStates.map {
                ExerciseStateSnapshot(
                    exerciseID: $0.key,
                    state: $0.value
                )
            },
            startedAt: startedAt,
            activeRestExerciseID:
                restTimerState?.exerciseID,
            restStartedAt:
                restTimerState?.startedAt,
            restTotalSeconds:
                restTimerState?.durationSeconds ?? 0
        )
    }

    private func persistenceDidSucceed(
        _ operation: StoreOperation
    ) {
        clearPersistenceError(for: operation)
    }

    private func persistenceDidFail(
        _ operation: StoreOperation,
        _ message: String
    ) {
        setPersistenceError(
            operation: operation,
            message: message
        )
    }

    private func restoreActiveWorkout() {
        do {
            guard let snapshot =
                    try persistenceCoordinator.load() else {
                clearPersistenceError(for: .loading)
                return
            }

            isRestoring = true

            activeWorkout = snapshot.activeWorkout
            exerciseStates = Dictionary(
                uniqueKeysWithValues:
                    snapshot.exerciseStates.map {
                        ($0.exerciseID, $0.state)
                    }
            )
            startedAt = snapshot.startedAt

            if let exerciseID = snapshot.activeRestExerciseID,
               let restStartedAt = snapshot.restStartedAt,
               snapshot.restTotalSeconds > 0 {
                restTimerState = RestTimerState(
                    exerciseID: exerciseID,
                    startedAt: restStartedAt,
                    durationSeconds:
                        snapshot.restTotalSeconds
                )
            } else {
                restTimerState = nil
            }

            elapsedSeconds = currentDurationSeconds()
            isRestoring = false

            startTimerIfNeeded()
            restoreRestTimerIfNeeded()
            clearPersistenceError(for: .loading)
        } catch {
            isRestoring = false

            do {
                try persistenceCoordinator
                    .deleteInvalidSnapshot()
            } catch {
                print(
                    "Failed to delete invalid active workout "
                    + "persistence: "
                    + error.localizedDescription
                )
            }

            print(
                "Failed to restore active workout: "
                + error.localizedDescription
            )

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't restore your in-progress workout. "
                    + "It may have been lost."
            )
        }
    }

    // MARK: - Formatting

    static func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60

        if hours > 0 {
            return String(
                format: "%d:%02d:%02d",
                hours,
                minutes,
                seconds
            )
        }

        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}
