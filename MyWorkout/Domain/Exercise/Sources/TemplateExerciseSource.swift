import Foundation

struct TemplateExerciseSource: ExerciseProviding {
    let exercises: [Exercise]

    init(templates: [WorkoutTemplate]) {
        exercises = templates.flatMap(\.exercises)
    }
}
