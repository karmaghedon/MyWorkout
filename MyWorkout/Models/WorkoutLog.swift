import Foundation

struct WorkoutLog: Identifiable, Codable {
    var id = UUID()
    let workoutName: String
    let date: Date
    let completedExercises: [CompletedExercise]
}

struct CompletedExercise: Identifiable, Codable {
    var id = UUID()
    let exerciseName: String
    let sets: [LoggedSet]
    let notes: String
}

struct LoggedSet: Identifiable, Codable {
    var id = UUID()
    let setNumber: Int
    let weight: Int
    let reps: Int
}
