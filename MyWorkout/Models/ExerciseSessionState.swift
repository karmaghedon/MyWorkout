import Foundation

struct ExerciseSessionState: Codable {
    var reps: Int = 10

    /// Canonical working weight stored in pounds.
    ///
    /// Display conversion belongs at the UI boundary.
    var workingWeightPounds: Double = 0

    var loggedSets: [LoggedSet] = []
    var suggestionMessage: String? = nil
    var notes: String = ""

    enum CodingKeys: String, CodingKey {
        case reps
        case workingWeightPounds = "weight"
        case loggedSets
        case suggestionMessage
        case notes
    }

    init(
        reps: Int = 10,
        workingWeightPounds: Double = 0,
        loggedSets: [LoggedSet] = [],
        suggestionMessage: String? = nil,
        notes: String = ""
    ) {
        self.reps = reps
        self.workingWeightPounds = workingWeightPounds
        self.loggedSets = loggedSets
        self.suggestionMessage = suggestionMessage
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 10
        loggedSets = try container.decodeIfPresent(
            [LoggedSet].self,
            forKey: .loggedSets
        ) ?? []
        suggestionMessage = try container.decodeIfPresent(
            String.self,
            forKey: .suggestionMessage
        )
        notes = try container.decodeIfPresent(
            String.self,
            forKey: .notes
        ) ?? ""

        // Migration support: historical active workouts may encode weight
        // as either Double or Int under the existing "weight" JSON key.
        if let doubleWeight = try? container.decodeIfPresent(
            Double.self,
            forKey: .workingWeightPounds
        ) {
            workingWeightPounds = doubleWeight
        } else if let intWeight = try? container.decodeIfPresent(
            Int.self,
            forKey: .workingWeightPounds
        ) {
            workingWeightPounds = Double(intWeight)
        } else {
            workingWeightPounds = 0
        }
    }
}
