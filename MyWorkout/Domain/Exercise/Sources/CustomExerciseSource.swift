import Foundation

struct CustomExerciseSource: ExerciseProviding {
    let exercises: [Exercise]

    init(
        exercises: [Exercise]
    ) {
        self.exercises = exercises
    }
}
