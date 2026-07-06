import Foundation

struct ExerciseSessionState: Codable {
    var reps: Int = 10
    var weight: Int = 0
    var loggedSets: [LoggedSet] = []
    var suggestionMessage: String? = nil
    var notes: String = ""
}
