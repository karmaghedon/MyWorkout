import Foundation

struct CustomExerciseDraft {
    var id: UUID

    var name: String
    var muscleGroup: MuscleGroup
    var equipment: ExerciseEquipment
    var instructions: String

    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var difficulty: String
    var tips: [String]
    var commonMistakes: [String]
    var warnings: [String]

    var minReps: Int
    var maxReps: Int
    var increaseAmount: Double
    var deloadAmount: Double
    var stallLimit: Int

    var exerciseType: ExerciseType
    var progressionStrategy: ProgressionStrategy

    init(
        id: UUID = UUID(),
        name: String = "",
        muscleGroup: MuscleGroup = .chest,
        equipment: ExerciseEquipment = .barbell,
        instructions: String = "",
        primaryMuscles: [String] = [],
        secondaryMuscles: [String] = [],
        difficulty: String = "Beginner",
        tips: [String] = [],
        commonMistakes: [String] = [],
        warnings: [String] = [],
        minReps: Int = 8,
        maxReps: Int = 12,
        increaseAmount: Double = 5,
        deloadAmount: Double = 5,
        stallLimit: Int = 3,
        exerciseType: ExerciseType = .compound,
        progressionStrategy: ProgressionStrategy =
            .doubleProgression
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
        self.minReps = minReps
        self.maxReps = maxReps
        self.increaseAmount = increaseAmount
        self.deloadAmount = deloadAmount
        self.stallLimit = stallLimit
        self.exerciseType = exerciseType
        self.progressionStrategy = progressionStrategy
    }
}

extension CustomExerciseDraft {
    init(
        exercise: Exercise
    ) {
        self.init(
            id: exercise.id,
            name: exercise.name,
            muscleGroup: exercise.muscleGroup,
            equipment: exercise.equipment,
            instructions: exercise.instructions,
            primaryMuscles: exercise.primaryMuscles,
            secondaryMuscles: exercise.secondaryMuscles,
            difficulty: exercise.difficulty,
            tips: exercise.tips,
            commonMistakes: exercise.commonMistakes,
            warnings: exercise.warnings,
            minReps: exercise.progressionRule.minReps,
            maxReps: exercise.progressionRule.maxReps,
            increaseAmount:
                exercise.progressionRule.increaseAmount,
            deloadAmount:
                exercise.progressionRule.deloadAmount,
            stallLimit:
                exercise.progressionRule.stallLimit,
            exerciseType: exercise.exerciseType,
            progressionStrategy:
                exercise.progressionStrategy
        )
    }
}

extension CustomExerciseDraft {
    var trimmedName: String {
        name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    var canSave: Bool {
        !trimmedName.isEmpty
            && minReps > 0
            && maxReps >= minReps
            && increaseAmount > 0
            && deloadAmount > 0
            && stallLimit > 0
    }
}

extension CustomExerciseDraft {
    func makeExercise() -> Exercise {
        Exercise(
            id: id,
            name: trimmedName,
            muscleGroup: muscleGroup,
            equipment: equipment,
            instructions: instructions
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            primaryMuscles:
                sanitized(primaryMuscles),
            secondaryMuscles:
                sanitized(secondaryMuscles),
            difficulty:
                difficulty.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            tips: sanitized(tips),
            commonMistakes:
                sanitized(commonMistakes),
            warnings: sanitized(warnings),
            progressionRule: ProgressionRule(
                minReps: minReps,
                maxReps: maxReps,
                increaseAmount: increaseAmount,
                deloadAmount: deloadAmount,
                stallLimit: stallLimit
            ),
            exerciseType: exerciseType,
            progressionStrategy:
                progressionStrategy
        )
    }

    private func sanitized(
        _ values: [String]
    ) -> [String] {
        values
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }
    }
}
