import Foundation

enum ExerciseRegistryFactory {
    static func make(
        templates: [WorkoutTemplate],
        logs: [WorkoutLog] = []
    ) -> ExerciseRegistry {
        let historicalSource =
            HistoricalExerciseReferenceSource(
                logs: logs
            )

        return ExerciseRegistry(
            sources: [
                BuiltInExerciseSource(),
                TemplateExerciseSource(
                    templates: templates
                )
            ],
            historicalReferences:
                historicalSource.references
        )
    }
}
