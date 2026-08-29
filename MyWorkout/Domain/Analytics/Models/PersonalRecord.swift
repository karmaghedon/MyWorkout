import Foundation

struct PersonalRecord: Identifiable, Equatable {
    let exerciseID: UUID?
    let exerciseName: String
    let weightPounds: Double
    let reps: Int

    var id: String {
        if let exerciseID {
            return "\(exerciseID.uuidString)-\(weightPounds)-\(reps)"
        }

        return "\(exerciseName)-\(weightPounds)-\(reps)"
    }
}
