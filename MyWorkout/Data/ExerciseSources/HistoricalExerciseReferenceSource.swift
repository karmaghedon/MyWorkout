import Foundation

struct HistoricalExerciseReferenceSource {
    let references: [HistoricalExerciseReference]

    init(logs: [WorkoutLog]) {
        var referencesByID: [
            String: HistoricalExerciseReference
        ] = [:]

        for log in logs {
            for completedExercise in log.completedExercises {
                let reference = HistoricalExerciseReference(
                    id: completedExercise.exerciseID,
                    name: completedExercise.exerciseName
                )

                referencesByID[reference.stableID] = reference
            }
        }

        references = referencesByID.values.sorted {
            $0.name.localizedCaseInsensitiveCompare(
                $1.name
            ) == .orderedAscending
        }
    }
}
