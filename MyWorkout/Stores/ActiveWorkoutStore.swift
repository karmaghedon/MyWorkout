import Foundation

final class ActiveWorkoutStore: ObservableObject {
    @Published var activeWorkout: Workout?
    @Published var exerciseStates: [UUID: ExerciseSessionState] = [:]
    @Published var startedAt: Date?
    @Published var elapsedSeconds: Int = 0

    private var workoutTimer: Timer?

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
        activeWorkout = nil
        exerciseStates = [:]
        startedAt = nil
        elapsedSeconds = 0
    }

    func finish() {
        stopTimer()
        activeWorkout = nil
        exerciseStates = [:]
        startedAt = nil
        elapsedSeconds = 0
    }

    func currentDurationSeconds() -> Int {
        guard let startedAt else { return elapsedSeconds }
        return max(0, Int(Date().timeIntervalSince(startedAt)))
    }

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
