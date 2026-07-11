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

    @Published var activeRestExerciseID: UUID? {
        didSet { schedulePersist() }
    }

    @Published var restStartedAt: Date? {
        didSet { schedulePersist() }
    }

    @Published var restTotalSeconds: Int = 0 {
        didSet { schedulePersist() }
    }

    @Published var restSecondsRemaining: Int = 0

    @Published private(set) var lastSaveError: String?
    @Published private(set) var lastLoadError: String?

    private let persistence: any ActiveWorkoutPersisting

    private let saveQueue = DispatchQueue(
        label: "com.myworkout.activeworkoutstore.save",
        qos: .utility
    )

    private var workoutTimer: Timer?
    private var isRestoring = false
    private var restTimer: Timer?
    private var persistWorkItem: DispatchWorkItem?

    init(
        persistence: any ActiveWorkoutPersisting =
            FileActiveWorkoutPersistence()
    ) {
        self.persistence = persistence
        restoreActiveWorkout()
    }

    var hasActiveWorkout: Bool {
        activeWorkout != nil
    }

    var hasLoggedSets: Bool {
        exerciseStates.values.contains { !$0.loggedSets.isEmpty }
    }

    var formattedElapsedTime: String {
        Self.formatDuration(elapsedSeconds)
    }

    // MARK: - Workout Lifecycle

    func start(_ workout: Workout) {
        persistWorkItem?.cancel()

        activeWorkout = workout
        exerciseStates = [:]
        startedAt = Date()
        elapsedSeconds = 0

        startTimerIfNeeded()
        persistActiveWorkout()
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
        stopRestTimer(clearPersistedState: true)

        activeRestExerciseID = exerciseID
        restStartedAt = Date()
        restTotalSeconds = totalSeconds
        restSecondsRemaining = totalSeconds

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
            activeRestExerciseID = nil
            restStartedAt = nil
            restTotalSeconds = 0
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

    private func startRestTimerIfNeeded() {
        guard restTimer == nil else {
            return
        }

        guard activeRestExerciseID != nil else {
            return
        }

        guard restTotalSeconds > 0 else {
            return
        }

        restTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            self?.updateRestSecondsRemaining()
        }
    }

    private func updateRestSecondsRemaining() {
        guard let restStartedAt else {
            restSecondsRemaining = 0
            return
        }

        let elapsed = Int(
            Date().timeIntervalSince(restStartedAt)
        )

        let remaining = max(
            0,
            restTotalSeconds - elapsed
        )

        restSecondsRemaining = remaining

        if remaining == 0 {
            stopRestTimer(clearPersistedState: true)
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

    // MARK: - Persistence Coordination

    private func schedulePersist() {
        guard !isRestoring else {
            return
        }

        persistWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.persistActiveWorkout()
        }

        persistWorkItem = workItem

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.3,
            execute: workItem
        )
    }

    private func clearActiveWorkout() {
        persistWorkItem?.cancel()

        isRestoring = true

        activeWorkout = nil
        exerciseStates = [:]
        startedAt = nil
        elapsedSeconds = 0

        activeRestExerciseID = nil
        restStartedAt = nil
        restTotalSeconds = 0
        restSecondsRemaining = 0

        isRestoring = false

        deletePersistedWorkout()
    }

    private func persistActiveWorkout() {
        guard !isRestoring else {
            return
        }

        guard let activeWorkout else {
            deletePersistedWorkout()
            return
        }

        let snapshot = ActiveWorkoutSnapshot(
            activeWorkout: activeWorkout,
            exerciseStates: exerciseStates.map {
                ExerciseStateSnapshot(
                    exerciseID: $0.key,
                    state: $0.value
                )
            },
            startedAt: startedAt,
            activeRestExerciseID: activeRestExerciseID,
            restStartedAt: restStartedAt,
            restTotalSeconds: restTotalSeconds
        )

        let persistence = persistence

        saveQueue.async { [weak self] in
            do {
                try persistence.save(snapshot)

                DispatchQueue.main.async {
                    self?.lastSaveError = nil
                }
            } catch {
                print(
                    "Failed to persist active workout: "
                    + error.localizedDescription
                )

                DispatchQueue.main.async {
                    self?.lastSaveError =
                        "Couldn't save your active workout. "
                        + "If the app closes, you may lose progress "
                        + "on this session."
                }
            }
        }
    }

    private func deletePersistedWorkout() {
        let persistence = persistence

        saveQueue.async { [weak self] in
            do {
                try persistence.delete()

                DispatchQueue.main.async {
                    self?.lastSaveError = nil
                }
            } catch {
                print(
                    "Failed to delete active workout persistence: "
                    + error.localizedDescription
                )

                DispatchQueue.main.async {
                    self?.lastSaveError =
                        "Couldn't clear the saved active workout."
                }
            }
        }
    }

    private func restoreActiveWorkout() {
        do {
            guard let snapshot = try persistence.load() else {
                lastLoadError = nil
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
            activeRestExerciseID =
                snapshot.activeRestExerciseID
            restStartedAt = snapshot.restStartedAt
            restTotalSeconds = snapshot.restTotalSeconds

            elapsedSeconds = currentDurationSeconds()

            isRestoring = false

            startTimerIfNeeded()
            restoreRestTimerIfNeeded()

            lastLoadError = nil
        } catch {
            isRestoring = false

            do {
                try persistence.delete()
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

            lastLoadError =
                "Couldn't restore your in-progress workout. "
                + "It may have been lost."
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
