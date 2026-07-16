import Foundation

enum ExerciseRegistryFactory {
    static func make(
        templates: [WorkoutTemplate],
        logs: [WorkoutLog],
        customExercises: [Exercise] = []
    ) -> ExerciseRegistry {
        let historicalSource = HistoricalExerciseReferenceSource(
            logs: logs
        )

        return ExerciseRegistry(
            sources: [
                BuiltInExerciseSource(),
                CustomExerciseSource(
                    exercises: customExercises
                ),
                TemplateExerciseSource(
                    templates: templates
                )
            ],
            historicalReferences: historicalSource.references
        )
    }
}
