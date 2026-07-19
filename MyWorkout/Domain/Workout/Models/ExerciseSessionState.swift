import Foundation

struct ExerciseSessionState: Codable {

    /// Number of repetitions currently selected for the next set.
    var targetReps: Int = 10

    /// Canonical working weight stored in pounds.
    ///
    /// Display conversion belongs at the UI boundary.
    var workingWeightPounds: Double = 0

    var loggedSets: [LoggedSet] = []
    var suggestionMessage: String? = nil
    var notes: String = ""

    enum CodingKeys: String, CodingKey {
        case targetReps = "reps"
        case workingWeightPounds = "weight"
        case loggedSets
        case suggestionMessage
        case notes
    }

    init(
        targetReps: Int = 10,
        workingWeightPounds: Double = 0,
        loggedSets: [LoggedSet] = [],
        suggestionMessage: String? = nil,
        notes: String = ""
    ) {
        self.targetReps = targetReps
        self.workingWeightPounds = workingWeightPounds
        self.loggedSets = loggedSets
        self.suggestionMessage = suggestionMessage
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        targetReps = try container.decodeIfPresent(
            Int.self,
            forKey: .targetReps
        ) ?? 10

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
