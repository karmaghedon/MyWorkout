import Foundation

final class ActiveWorkoutStore: ObservableObject {
    @Published var activeWorkout: Workout?
    @Published var exerciseStates: [UUID: ExerciseSessionState] = [:]

    var hasActiveWorkout: Bool {
        activeWorkout != nil
    }

    var hasLoggedSets: Bool {
        exerciseStates.values.contains { !$0.loggedSets.isEmpty }
    }

    func start(_ workout: Workout) {
        activeWorkout = workout
        exerciseStates = [:]
    }

    func cancel() {
        activeWorkout = nil
        exerciseStates = [:]
    }

    func finish() {
        activeWorkout = nil
        exerciseStates = [:]
    }
}
