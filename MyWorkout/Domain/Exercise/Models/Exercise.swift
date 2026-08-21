import Foundation

struct Exercise: Identifiable, Codable {
    var id: UUID

    let name: String
    let muscleGroup: MuscleGroup
    let equipment: ExerciseEquipment
    let instructions: String

    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let difficulty: String
    let tips: [String]
    let commonMistakes: [String]
    let warnings: [String]

    let progressionRule: ProgressionRule
    let exerciseType: ExerciseType
    let progressionStrategy: ProgressionStrategy

    /// How many working sets a session should show for this exercise by
    /// default. Configured once per template (`CreateWorkoutTemplateView`,
    /// `TemplateEditorView`) — since `WorkoutTemplate.exercises` holds
    /// value copies of `Exercise`, the same exercise can carry a different
    /// `targetSets` in different templates with no extra keying needed.
    var targetSets: Int = 3

    /// A per-template starting weight override, in canonical pounds. `nil`
    /// (the default) means "no override" — `WorkoutSessionEngine.initialState`
    /// falls back to its existing behavior (progression history if any,
    /// otherwise the equipment-derived default) exactly as it did before
    /// this field existed. Only used when there's no prior performance for
    /// the exercise yet; once real history exists, progression drives the
    /// weight, not the template.
    var targetWeightPounds: Double?

    /// Groups this exercise with others sharing the same id into a
    /// superset/circuit — perform them back-to-back with no rest between
    /// members, resting only after the last member of the group. `nil`
    /// (the default) means "not grouped," unchanged single-exercise
    /// behavior. Per-template, same as `targetSets`/`targetWeightPounds`:
    /// `WorkoutTemplate.exercises` holds value copies, so the same
    /// exercise can be grouped differently (or not at all) across
    /// different templates.
    var supersetGroupID: UUID?

    var usesBarbell: Bool {
        equipment.usesBarbell
    }

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup,
        equipment: ExerciseEquipment,
        instructions: String,
        primaryMuscles: [String] = [],
        secondaryMuscles: [String] = [],
        difficulty: String = "Beginner",
        tips: [String] = [],
        commonMistakes: [String] = [],
        warnings: [String] = [],
        progressionRule: ProgressionRule,
        exerciseType: ExerciseType,
        progressionStrategy: ProgressionStrategy,
        targetSets: Int = 3,
        targetWeightPounds: Double? = nil,
        supersetGroupID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.instructions = instructions
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.difficulty = difficulty
        self.tips = tips
        self.commonMistakes = commonMistakes
        self.warnings = warnings
        self.progressionRule = progressionRule
        self.exerciseType = exerciseType
        self.progressionStrategy = progressionStrategy
        self.targetSets = targetSets
        self.targetWeightPounds = targetWeightPounds
        self.supersetGroupID = supersetGroupID
    }

    // MARK: - Codable

    /// Hand-written on both sides: `targetSets` is a new field, and every
    /// `Exercise` already persisted on a device (inside a saved
    /// `WorkoutTemplate`, a custom exercise, an in-progress workout
    /// snapshot, an exported backup) predates it. A synthesized decoder
    /// would require the key on every decode and throw on all of that
    /// existing data on first launch after this shipped — `decodeIfPresent
    /// ?? 3` avoids that, the same pattern already used elsewhere in this
    /// codebase (e.g. `ExerciseSessionState.init(from:)`).
    private enum CodingKeys: String, CodingKey {
        case id, name, muscleGroup, equipment, instructions
        case primaryMuscles, secondaryMuscles, difficulty
        case tips, commonMistakes, warnings
        case progressionRule, exerciseType, progressionStrategy
        case targetSets
        case targetWeightPounds
        case supersetGroupID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        muscleGroup = try container.decode(MuscleGroup.self, forKey: .muscleGroup)
        equipment = try container.decode(ExerciseEquipment.self, forKey: .equipment)
        instructions = try container.decode(String.self, forKey: .instructions)
        primaryMuscles = try container.decode([String].self, forKey: .primaryMuscles)
        secondaryMuscles = try container.decode([String].self, forKey: .secondaryMuscles)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        tips = try container.decode([String].self, forKey: .tips)
        commonMistakes = try container.decode([String].self, forKey: .commonMistakes)
        warnings = try container.decode([String].self, forKey: .warnings)
        progressionRule = try container.decode(ProgressionRule.self, forKey: .progressionRule)
        exerciseType = try container.decode(ExerciseType.self, forKey: .exerciseType)
        progressionStrategy = try container.decode(ProgressionStrategy.self, forKey: .progressionStrategy)

        targetSets = try container.decodeIfPresent(Int.self, forKey: .targetSets) ?? 3
        targetWeightPounds = try container.decodeIfPresent(Double.self, forKey: .targetWeightPounds)
        supersetGroupID = try container.decodeIfPresent(UUID.self, forKey: .supersetGroupID)
    }

    func encode(
        to encoder: Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(muscleGroup, forKey: .muscleGroup)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(primaryMuscles, forKey: .primaryMuscles)
        try container.encode(secondaryMuscles, forKey: .secondaryMuscles)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(tips, forKey: .tips)
        try container.encode(commonMistakes, forKey: .commonMistakes)
        try container.encode(warnings, forKey: .warnings)
        try container.encode(progressionRule, forKey: .progressionRule)
        try container.encode(exerciseType, forKey: .exerciseType)
        try container.encode(
            progressionStrategy,
            forKey: .progressionStrategy
        )
        try container.encode(targetSets, forKey: .targetSets)
        try container.encodeIfPresent(targetWeightPounds, forKey: .targetWeightPounds)
        try container.encodeIfPresent(supersetGroupID, forKey: .supersetGroupID)
    }
}
