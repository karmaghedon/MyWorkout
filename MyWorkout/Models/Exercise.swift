import Foundation

struct Exercise: Identifiable, Codable {
    var id: UUID
    let name: String
    let muscleGroup: String
    let equipment: String
    let instructions: String
    let progressionRule: ProgressionRule
    let exerciseType: ExerciseType
    let progressionStrategy: ProgressionStrategy

    var usesBarbell: Bool {
        equipment.lowercased().contains("barbell")
    }

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: String,
        equipment: String,
        instructions: String,
        progressionRule: ProgressionRule,
        exerciseType: ExerciseType,
        progressionStrategy: ProgressionStrategy
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.instructions = instructions
        self.progressionRule = progressionRule
        self.exerciseType = exerciseType
        self.progressionStrategy = progressionStrategy
    }
}
