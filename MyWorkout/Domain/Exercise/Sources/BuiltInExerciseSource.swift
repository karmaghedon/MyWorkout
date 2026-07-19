import Foundation

struct BuiltInExerciseSource: ExerciseProviding {
    let exercises: [Exercise]

    init(
        exercises: [Exercise] = SeedData.exercises
    ) {
        self.exercises = exercises
    }
}
