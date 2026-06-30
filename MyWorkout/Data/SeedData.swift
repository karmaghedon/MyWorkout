import Foundation

struct SeedData {
    static let exercises: [Exercise] = [
        Exercise(name: "Bench Press", muscleGroup: "Chest", equipment: "Barbell", instructions: "",progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .compound),
        Exercise(name: "Front Squat", muscleGroup: "Legs", equipment: "Barbell", instructions: "", progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .compound),
        Exercise(name: "Romanian Deadlift", muscleGroup: "Hamstrings/Glutes", equipment: "Barbell", instructions: "", progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .compound),
        Exercise(name: "Incline Bench Press", muscleGroup: "Chest", equipment: "Dumbbells", instructions: "", progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .compound),
        Exercise(name: "Incline Row", muscleGroup: "Back", equipment: "Dumbbells", instructions: "", progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .compound),
        Exercise(name: "Bent Over Row - Underhand", muscleGroup: "Back", equipment: "Barbell", instructions: "", progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .compound),
        Exercise(name: "Pull Up", muscleGroup: "Back", equipment: "Bodyweight", instructions: "", progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .bodyweight),
        Exercise(name: "Chin Up", muscleGroup: "Back/Biceps", equipment: "Bodyweight", instructions: "",progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
        exerciseType: .bodyweight),
        Exercise(name: "Chest Dip", muscleGroup: "Chest/Triceps", equipment: "Bodyweight", instructions: "", progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
        exerciseType: .bodyweight),
        Exercise(name: "Strict Military Press", muscleGroup: "Shoulders", equipment: "Barbell", instructions: "", progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .compound),
        Exercise(name: "Glute Bridge", muscleGroup: "Glutes", equipment: "Barbell", instructions: "", progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .compound),
        Exercise(name: "Goblet Squat", muscleGroup: "Legs", equipment: "Kettlebell/Dumbbell", instructions: "", progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .compound),
        Exercise(name: "Inverted Row", muscleGroup: "Back", equipment: "Bodyweight", instructions: "",progressionRule: ProgressionRule(minReps: 8, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
        exerciseType: .bodyweight),
        Exercise(name: "Face Pull", muscleGroup: "Rear Delts/Upper Back", equipment: "Cable/Band", instructions: "", progressionRule: ProgressionRule(minReps: 10, maxReps: 15, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
        exerciseType: .isolation),
        Exercise(name: "Skullcrusher", muscleGroup: "Triceps", equipment: "Barbell", instructions: "", progressionRule: ProgressionRule(minReps: 10, maxReps: 15, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .isolation),
        Exercise(name: "Triceps Extension", muscleGroup: "Triceps", equipment: "Barbell", instructions: "", progressionRule: ProgressionRule(minReps: 10, maxReps: 15, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .isolation),
        Exercise(name: "Bicep Curl", muscleGroup: "Biceps", equipment: "Barbell", instructions: "", progressionRule: ProgressionRule(minReps: 10, maxReps: 15, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .isolation),
        Exercise(name: "Hammer Curl", muscleGroup: "Biceps/Forearms", equipment: "Dumbbell", instructions: "", progressionRule: ProgressionRule(minReps: 10, maxReps: 15, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
                 exerciseType: .isolation)
    ]

    static let workouts: [Workout] = [
        Workout(name: "Workout A", exercises: exercises),
        Workout(name: "Workout B", exercises: exercises),
        Workout(name: "Workout C", exercises: exercises)
    ]
    
    static let defaultTemplates: [WorkoutTemplate] = [
        WorkoutTemplate(
            name: "Workout A",
            exercises: exercises.filter {
                [
                    "Front Squat",
                    "Bench Press",
                    "Incline Row",
                    "Chin Up",
                    "Chest Dip",
                    "Glute Bridge",
                    "Skullcrusher",
                    "Bicep Curl",
                    "Face Pull"
                ].contains($0.name)
            }
        ),
        WorkoutTemplate(
            name: "Workout B",
            exercises: exercises.filter {
                [
                    "Romanian Deadlift",
                    "Front Squat",
                    "Incline Bench Press",
                    "Incline Row",
                    "Pull Up",
                    "Strict Military Press",
                    "Triceps Extension",
                    "Hammer Curl"
                ].contains($0.name)
            }
        )
    ]
}
