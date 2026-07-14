import Foundation

struct AnalyticsInput: Sendable {
    let logs: [AnalyticsWorkoutLog]
    let exercises: [AnalyticsExerciseReference]
}

struct AnalyticsWorkoutLog: Sendable {
    let id: UUID
    let date: Date
    let exercises: [AnalyticsCompletedExercise]
}

struct AnalyticsCompletedExercise: Sendable {
    let exerciseID: UUID?
    let exerciseName: String
    let sets: [AnalyticsLoggedSet]
}

struct AnalyticsLoggedSet: Sendable {
    let weightPounds: Double
    let reps: Int
}

struct AnalyticsExerciseReference: Sendable {
    let id: UUID
    let name: String
    let muscleGroup: MuscleGroup
}
