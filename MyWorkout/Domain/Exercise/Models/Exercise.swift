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
        progressionStrategy: ProgressionStrategy
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
    }
}
