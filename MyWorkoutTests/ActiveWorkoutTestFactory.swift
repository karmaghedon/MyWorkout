import Foundation
@testable import MyWorkout

enum ActiveWorkoutTestFactory {

    static func makeWorkout(
        id: UUID = UUID(),
        name: String = "Test Workout",
        exercises: [Exercise]? = nil
    ) -> Workout {
        Workout(
            id: id,
            name: name,
            exercises:
                exercises
                ?? SeedData.defaultTemplates
                    .first?
                    .exercises
                ?? []
        )
    }

    static func makeSnapshot(
        workout: Workout? = nil,
        exerciseStates:
            [UUID: ExerciseSessionState] = [:],
        startedAt: Date? = Date(
            timeIntervalSince1970:
                2_000_000_000
        ),
        activeRestExerciseID: UUID? = nil,
        restStartedAt: Date? = nil,
        restTotalSeconds: Int = 0
    ) -> ActiveWorkoutSnapshot {
        ActiveWorkoutSnapshot(
            activeWorkout:
                workout
                ?? makeWorkout(),
            exerciseStates:
                exerciseStates.map {
                    ExerciseStateSnapshot(
                        exerciseID: $0.key,
                        state: $0.value
                    )
                },
            startedAt: startedAt,
            activeRestExerciseID:
                activeRestExerciseID,
            restStartedAt:
                restStartedAt,
            restTotalSeconds:
                restTotalSeconds
        )
    }
}
