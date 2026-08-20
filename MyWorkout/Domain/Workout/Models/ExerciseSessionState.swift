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

    /// Warm-up rows the user has checked off in the Checklist layout, keyed
    /// by `warmupKey(weight:reps:)` rather than `WarmupSet.id` — that id is
    /// a fresh `UUID()` on every call to `WarmupEngine.generateWarmups(...)`,
    /// which runs fresh on every render since `warmups` is a computed
    /// property, not stored. An id-keyed set would never match between
    /// renders. Weight alone isn't enough either: `WarmupEngine`'s barbell
    /// ramp starts with two sets at the same empty-bar weight (10 reps,
    /// then 8), so a weight-only key would mark both complete at once.
    /// Weight+reps together are deterministic for a given working weight,
    /// and if the user changes their working weight mid-warm-up, stale
    /// completions for pairs that no longer appear simply stop mattering.
    var completedWarmupKeys: Set<String> = []

    static func warmupKey(weight: Double, reps: Int) -> String {
        "\(weight)|\(reps)"
    }

    /// Extra working sets added mid-session via the Checklist layout's
    /// "Add Set" button, on top of `Exercise.targetSets`. Deliberately
    /// session-scoped, not template-scoped: tapping it is a one-off
    /// "I felt like doing one more today," not a request to redefine the
    /// template for next time.
    var extraWorkingSets: Int = 0

    enum CodingKeys: String, CodingKey {
        case targetReps = "reps"
        case workingWeightPounds = "weight"
        case loggedSets
        case suggestionMessage
        case notes
        case completedWarmupKeys
        case extraWorkingSets
    }

    init(
        targetReps: Int = 10,
        workingWeightPounds: Double = 0,
        loggedSets: [LoggedSet] = [],
        suggestionMessage: String? = nil,
        notes: String = "",
        completedWarmupKeys: Set<String> = [],
        extraWorkingSets: Int = 0
    ) {
        self.targetReps = targetReps
        self.workingWeightPounds = workingWeightPounds
        self.loggedSets = loggedSets
        self.suggestionMessage = suggestionMessage
        self.notes = notes
        self.completedWarmupKeys = completedWarmupKeys
        self.extraWorkingSets = extraWorkingSets
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

        completedWarmupKeys = try container.decodeIfPresent(
            Set<String>.self,
            forKey: .completedWarmupKeys
        ) ?? []

        extraWorkingSets = try container.decodeIfPresent(
            Int.self,
            forKey: .extraWorkingSets
        ) ?? 0
    }
}
