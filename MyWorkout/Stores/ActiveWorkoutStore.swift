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

    private let legacyDefaultsKey = "active_workout_session"
    private let fileURL: URL
    private let saveQueue = DispatchQueue(label: "com.myworkout.activeworkoutstore.save", qos: .utility)
    private var workoutTimer: Timer?
    private var isRestoring = false
    private var restTimer: Timer?
    private var persistWorkItem: DispatchWorkItem?

    init() {
        fileURL = Self.resolveFileURL()
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
    // MARK: - Workout lifecycle
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
    
    // MARK: - Exercise state
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
    
    // MARK: - Rest timer
    func startRestTimer(for exerciseID: UUID, totalSeconds: Int) {
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

    // MARK: - Workout timer
    private func startTimerIfNeeded() {
        guard workoutTimer == nil else { return }

        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
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

    // MARK: - Persistence
    private func schedulePersist() {
        guard !isRestoring else { return}
        persistWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.persistActiveWorkout()
        }
        persistWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
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
        deletePersistedFile()
    }

    private func persistActiveWorkout() {
        guard !isRestoring else { return }

        guard let activeWorkout else {
            deletePersistedFile()
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

        let destination = fileURL

        saveQueue.async { [weak self] in
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: destination, options: .atomic)

                DispatchQueue.main.async {
                    self?.lastSaveError = nil
                }
            } catch {
                print("Failed to persist active workout: \(error.localizedDescription)")

                DispatchQueue.main.async {
                    self?.lastSaveError = "Couldn't save your active workout. If the app closes, you may lose progress on this session."
                }
            }
        }
    }

    private func deletePersistedFile() {
        let destination = fileURL

        saveQueue.async {
            try? FileManager.default.removeItem(at: destination)
        }
    }

    private static func resolveFileURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("MyWorkout", isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory.appendingPathComponent("active_workout_session.json")
    }

    private func restoreActiveWorkout() {
        let data: Data
        var didMigrateFromLegacyStorage = false

        if !FileManager.default.fileExists(atPath: fileURL.path),
           let legacyData = UserDefaults.standard.data(forKey: legacyDefaultsKey) {
            // Migrate from the old UserDefaults-based storage. Write it
            // through to the new file so future launches skip this path.
            data = legacyData
            didMigrateFromLegacyStorage = true
            UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
        } else {
            guard let fileData = try? Data(contentsOf: fileURL) else { return }
            data = fileData
        }

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

            // Properties set while isRestoring was true don't trigger
            // schedulePersist(), so a fresh migration wouldn't otherwise get
            // written to the new file until the next edit. Persist it now so
            // the migration can't silently lose data if the app is closed
            // before anything changes.
            if didMigrateFromLegacyStorage {
                persistActiveWorkout()
            }

            lastLoadError = nil
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            print("Failed to restore active workout: \(error.localizedDescription)")
            lastLoadError = "Couldn't restore your in-progress workout. It may have been lost."
        }
    }

    // MARK: - Formatting
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
