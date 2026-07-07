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
    let weight: Double
    let reps: Int
    
    enum CodingKeys: String, CodingKey {
        case id, setNumber, weight, reps
    }
    
    init(id: UUID = UUID(), setNumber: Int, weight: Double, reps: Int) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        setNumber = try container.decode(Int.self, forKey: .setNumber)
        reps = try container.decode(Int.self, forKey: .reps)
        
        // Support both Int and Double for amounts (migration compatibility)
        if let doubleWeight = try? container.decode(Double.self, forKey: .weight) {
            weight = doubleWeight
        } else if let intWeight = try? container.decode(Int.self, forKey: .weight) {
            weight = Double(intWeight)
        } else {
            weight = 0
        }
    }
}
