import Foundation
@testable import MyWorkout

enum WorkoutLogTestFactory {

    static func make(
        name: String = "Test Workout",
        date: Date = Date(
            timeIntervalSince1970: 2_000_000_000
        ),
        completedExercises: [CompletedExercise] = []
    ) -> WorkoutLog {
        WorkoutLog(
            workoutName: name,
            date: date,
            completedExercises: completedExercises
        )
    }

    static func make(
        name: String,
        daysAgo: Int
    ) -> WorkoutLog {
        make(
            name: name,
            date: Date(
                timeIntervalSince1970:
                    2_000_000_000
                    - Double(daysAgo * 86_400)
            )
        )
    }
}
