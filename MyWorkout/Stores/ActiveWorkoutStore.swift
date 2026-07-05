import SwiftUI
import Foundation

final class ActiveWorkoutStore: ObservableObject {
    @Published var activeWorkout: Workout? {
        didSet { persistActiveWorkout() }
    }

    @Published var exerciseStates: [UUID: ExerciseSessionState] = [:] {
        didSet { persistActiveWorkout() }
    }

    @Published var startedAt: Date? {
        didSet { persistActiveWorkout() }
    }

    @Published var elapsedSeconds: Int = 0
    
    @Published var activeRestExerciseID: UUID? {
        didSet { persistActiveWorkout() }
    }

    @Published var restStartedAt: Date? {
        didSet { persistActiveWorkout() }
    }

    @Published var restTotalSeconds: Int = 0 {
        didSet { persistActiveWorkout() }
    }

    @Published var restSecondsRemaining: Int = 0

    private let persistenceKey = "active_workout_session"
    private var workoutTimer: Timer?
    private var isRestoring = false
    private var restTimer: Timer?

    init() {
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

    func start(_ workout: Workout) {
        activeWorkout = workout
        exerciseStates = [:]
        startedAt = Date()
        elapsedSeconds = 0
        startTimerIfNeeded()
        persistActiveWorkout()
    }

    func resumeTimer() {
        guard activeWorkout != nil else { return }

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
        guard let startedAt else { return elapsedSeconds }
        return max(0, Int(Date().timeIntervalSince(startedAt)))
    }
    
    func startRestTimer(for exerciseID: UUID, totalSeconds: Int) {
        stopRestTimer(clearPersistedState: true)

        activeRestExerciseID = exerciseID
        restStartedAt = Date()
        restTotalSeconds = totalSeconds
        restSecondsRemaining = totalSeconds

        startRestTimerIfNeeded()
        persistActiveWorkout()
    }

    func stopRestTimer(clearPersistedState: Bool = true) {
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

    func binding(for exerciseID: UUID) -> Binding<ExerciseSessionState> {
        Binding(
            get: {
                self.exerciseStates[exerciseID] ?? ExerciseSessionState()
            },
            set: { newState in
                self.exerciseStates[exerciseID] = newState
            }
        )
    }
    
    private func startRestTimerIfNeeded() {
        guard restTimer == nil else { return }
        guard activeRestExerciseID != nil else { return }
        guard restTotalSeconds > 0 else { return }

        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateRestSecondsRemaining()
        }
    }

    private func updateRestSecondsRemaining() {
        guard let restStartedAt else {
            restSecondsRemaining = 0
            return
        }

        let elapsed = Int(Date().timeIntervalSince(restStartedAt))
        let remaining = max(0, restTotalSeconds - elapsed)
        restSecondsRemaining = remaining

        if remaining == 0 {
            stopRestTimer(clearPersistedState: true)
        }
    }

    private func startTimerIfNeeded() {
        guard workoutTimer == nil else { return }

        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateElapsedSeconds()
        }
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
    
    func logSet(for exerciseID: UUID) {
        WorkoutSessionEngine.logSet(
            for: exerciseID,
            in: &exerciseStates
        )
    }

    func deleteSet(setID: UUID, for exerciseID: UUID) {
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
            if exerciseStates[exercise.id] == nil {
                let performances = logStore.lastPerformances(
                    for: exercise,
                    limit: exercise.progressionRule.stallLimit
                )

                exerciseStates[exercise.id] = WorkoutSessionEngine.initialState(
                    for: exercise,
                    latestPerformance: performances.first,
                    previousPerformances: Array(performances.dropFirst()),
                    equipmentInventory: equipmentInventory
                )
            }
        }
    }
    
    private func stopTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }

    private func updateElapsedSeconds() {
        elapsedSeconds = currentDurationSeconds()
    }

    private func clearActiveWorkout() {
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
        UserDefaults.standard.removeObject(forKey: persistenceKey)
    }

    private func persistActiveWorkout() {
        guard !isRestoring else { return }

        guard let activeWorkout else {
            UserDefaults.standard.removeObject(forKey: persistenceKey)
            return
        }

        let snapshot = ActiveWorkoutSnapshot(
            activeWorkout: activeWorkout,
            exerciseStates: exerciseStates.map { ExerciseStateSnapshot(exerciseID: $0.key, state: $0.value) },
            startedAt: startedAt,
            activeRestExerciseID: activeRestExerciseID,
            restStartedAt: restStartedAt,
            restTotalSeconds: restTotalSeconds
        )

        do {
            let data = try JSONEncoder().encode(snapshot)
            UserDefaults.standard.set(data, forKey: persistenceKey)
        } catch {
            print("Failed to persist active workout: \(error.localizedDescription)")
        }
    }

    private func restoreActiveWorkout() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }

        do {
            let snapshot = try JSONDecoder().decode(ActiveWorkoutSnapshot.self, from: data)

            isRestoring = true
            activeWorkout = snapshot.activeWorkout
            exerciseStates = Dictionary(
                uniqueKeysWithValues: snapshot.exerciseStates.map { ($0.exerciseID, $0.state) }
            )
            startedAt = snapshot.startedAt

            activeRestExerciseID = snapshot.activeRestExerciseID
            restStartedAt = snapshot.restStartedAt
            restTotalSeconds = snapshot.restTotalSeconds

            elapsedSeconds = currentDurationSeconds()
            isRestoring = false

            if activeWorkout != nil {
                startTimerIfNeeded()
                restoreRestTimerIfNeeded()
            }
        } catch {
            UserDefaults.standard.removeObject(forKey: persistenceKey)
            print("Failed to restore active workout: \(error.localizedDescription)")
        }
    }

    static func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct ActiveWorkoutSnapshot: Codable {
    let activeWorkout: Workout
    let exerciseStates: [ExerciseStateSnapshot]
    let startedAt: Date?
    let activeRestExerciseID: UUID?
    let restStartedAt: Date?
    let restTotalSeconds: Int
}

private struct ExerciseStateSnapshot: Codable {
    let exerciseID: UUID
    let state: ExerciseSessionState
}
