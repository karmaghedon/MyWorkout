import Foundation

struct Exercise: Identifiable, Codable {
    var id: UUID

    let name: String

    // Existing (keep for compatibility)
    let muscleGroup: MuscleGroup
    let equipment: ExerciseEquipment
    let instructions: String

    // New metadata
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
}
