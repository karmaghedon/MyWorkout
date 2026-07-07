import Foundation

struct ExerciseSessionState: Codable {
    var reps: Int = 10
    var weight: Double = 0
    var loggedSets: [LoggedSet] = []
    var suggestionMessage: String? = nil
    var notes: String = ""
    
    enum CodingKeys: String, CodingKey {
        case reps, weight, loggedSets, suggestionMessage, notes
    }
    
    init(
        reps: Int = 10,
        weight: Double = 0,
        loggedSets: [LoggedSet] = [],
        suggestionMessage: String? = nil,
        notes: String = ""
    ) {
        self.reps = reps
        self.weight = weight
        self.loggedSets = loggedSets
        self.suggestionMessage = suggestionMessage
        self.notes = notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 10
        loggedSets = try container.decodeIfPresent([LoggedSet].self, forKey: .loggedSets) ?? []
        suggestionMessage = try container.decodeIfPresent(String.self, forKey: .suggestionMessage)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        
        // Support both Int and Double for weight (migration capability)
        if let  doubleWeight =  try? container.decodeIfPresent(Double.self, forKey: .weight) {
            weight = doubleWeight
        } else if let intWeight = try? container.decodeIfPresent(Int.self, forKey: .weight) {
            weight = Double(intWeight)
        } else {
            weight = 0
        }

    }
}
