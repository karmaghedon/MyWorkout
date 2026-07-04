import Foundation

struct WorkoutLog: Identifiable, Codable {
    var id = UUID()
    let workoutName: String
    let date: Date
    let durationSeconds: Int?
    let completedExercises: [CompletedExercise]

    init(
        id: UUID = UUID(),
        workoutName: String,
        date: Date,
        durationSeconds: Int? = nil,
        completedExercises: [CompletedExercise]
    ) {
        self.id = id
        self.workoutName = workoutName
        self.date = date
        self.durationSeconds = durationSeconds
        self.completedExercises = completedExercises
    }
}

struct CompletedExercise: Identifiable, Codable {
    var id = UUID()
    let exerciseID: UUID?
    let exerciseName: String
    let sets: [LoggedSet]
    let notes: String

    init(
        id: UUID = UUID(),
        exerciseID: UUID? = nil,
        exerciseName: String,
        sets: [LoggedSet],
        notes: String
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.sets = sets
        self.notes = notes
    }
}

struct LoggedSet: Identifiable, Codable {
    var id = UUID()
    let setNumber: Int
    let weight: Int
    let reps: Int
}
