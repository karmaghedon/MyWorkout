import Foundation

enum AnalyticsInputFactory {
    static func make(
        logs: [WorkoutLog],
        registry: ExerciseRegistry
    ) -> AnalyticsInput {
        AnalyticsInput(
            logs: logs.map(makeLog),
            exercises: registry.exercises.map(makeExercise)
        )
    }

    private static func makeLog(
        _ log: WorkoutLog
    ) -> AnalyticsWorkoutLog {
        AnalyticsWorkoutLog(
            id: log.id,
            date: log.date,
            exercises: log.completedExercises.map(
                makeCompletedExercise
            )
        )
    }

    private static func makeCompletedExercise(
        _ exercise: CompletedExercise
    ) -> AnalyticsCompletedExercise {
        AnalyticsCompletedExercise(
            exerciseID: exercise.exerciseID,
            exerciseName: exercise.exerciseName,
            sets: exercise.sets.map {
                AnalyticsLoggedSet(
                    weightPounds: $0.weight,
                    reps: $0.reps
                )
            }
        )
    }

    private static func makeExercise(
        _ exercise: Exercise
    ) -> AnalyticsExerciseReference {
        AnalyticsExerciseReference(
            id: exercise.id,
            name: exercise.name,
            muscleGroup: exercise.muscleGroup
        )
    }
}
