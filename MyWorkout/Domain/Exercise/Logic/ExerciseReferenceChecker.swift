import Foundation

struct ExerciseReferenceStatus: Equatable {
    let isUsedByTemplates: Bool
    let isUsedByHistory: Bool
    let isUsedByActiveWorkout: Bool

    var isReferenced: Bool {
        isUsedByTemplates
            || isUsedByHistory
            || isUsedByActiveWorkout
    }
}

enum ExerciseReferenceChecker {
    static func status(
        for exerciseID: UUID,
        templates: [WorkoutTemplate],
        logs: [WorkoutLog],
        activeWorkout: Workout?
    ) -> ExerciseReferenceStatus {
        ExerciseReferenceStatus(
            isUsedByTemplates: templates.contains { template in
                template.exercises.contains {
                    $0.id == exerciseID
                }
            },
            isUsedByHistory: logs.contains { log in
                log.completedExercises.contains {
                    $0.exerciseID == exerciseID
                }
            },
            isUsedByActiveWorkout:
                activeWorkout?.exercises.contains {
                    $0.id == exerciseID
                } ?? false
        )
    }
}
