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
    /// by `warmupKey(index:weight:reps:)` rather than `WarmupSet.id` — that
    /// id is a fresh `UUID()` on every call to
    /// `WarmupEngine.generateWarmups(...)`, which runs fresh on every
    /// render since `warmups` is a computed property, not stored. An
    /// id-keyed set would never match between renders. Weight alone isn't
    /// enough either: `WarmupEngine`'s barbell ramp starts with two sets at
    /// the same empty-bar weight (10 reps, then 8), so a weight-only key
    /// would mark both complete at once. Weight+reps alone isn't enough
    /// either: "Add Warm-up Set" seeds the new row from the previous row's
    /// weight/reps, so right after adding one, two rows briefly share an
    /// identical weight+reps pair — a content-only key would mark both
    /// complete the moment either one is checked. Position is included to
    /// disambiguate that case; it's still safe across a working-weight
    /// change mid-warm-up (the same reasoning as before) because the
    /// weight+reps at a given position changes too, so a stale key simply
    /// stops matching anything rather than misattaching to the wrong row.
    var completedWarmupKeys: Set<String> = []

    static func warmupKey(index: Int, weight: Double, reps: Int) -> String {
        "\(index)|\(weight)|\(reps)"
    }

    /// Extra working sets added mid-session via the Checklist layout's
    /// "Add Set" button, on top of `Exercise.targetSets`. Deliberately
    /// session-scoped, not template-scoped: tapping it is a one-off
    /// "I felt like doing one more today," not a request to redefine the
    /// template for next time.
    var extraWorkingSets: Int = 0

    /// User-edited or user-added warm-up sets, overriding whatever
    /// `WarmupEngine.generateWarmups` would otherwise compute. `nil` (the
    /// default) means "use the auto-generated ramp" — the same override-vs-
    /// default pattern as `targetWeightPounds` elsewhere in this codebase.
    /// Once the user edits a single warm-up or adds one, the whole list
    /// becomes explicit so the auto-generated ramp doesn't reappear
    /// underneath their edits on the next render.
    var customWarmups: [WarmupSet]? = nil

    enum CodingKeys: String, CodingKey {
        case targetReps = "reps"
        case workingWeightPounds = "weight"
        case loggedSets
        case suggestionMessage
        case notes
        case completedWarmupKeys
        case extraWorkingSets
        case customWarmups
    }

    init(
        targetReps: Int = 10,
        workingWeightPounds: Double = 0,
        loggedSets: [LoggedSet] = [],
        suggestionMessage: String? = nil,
        notes: String = "",
        completedWarmupKeys: Set<String> = [],
        extraWorkingSets: Int = 0,
        customWarmups: [WarmupSet]? = nil
    ) {
        self.targetReps = targetReps
        self.workingWeightPounds = workingWeightPounds
        self.loggedSets = loggedSets
        self.suggestionMessage = suggestionMessage
        self.notes = notes
        self.completedWarmupKeys = completedWarmupKeys
        self.extraWorkingSets = extraWorkingSets
        self.customWarmups = customWarmups
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

        customWarmups = try container.decodeIfPresent(
            [WarmupSet].self,
            forKey: .customWarmups
        )
    }
}
