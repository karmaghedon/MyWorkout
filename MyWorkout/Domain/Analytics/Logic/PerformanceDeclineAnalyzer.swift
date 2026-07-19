import Foundation

struct PerformanceDeclineAnalyzer {

    static func warnings(
        logs: [WorkoutLog]
    ) -> [RecoveryWarning] {
        let grouped = groupPerformancesByExercise(
            logs: logs
        )

        return grouped.compactMap { _, performances in
            let sorted = performances.sorted {
                $0.date > $1.date
            }

            let recent = Array(sorted.prefix(3))

            guard recent.count == 3 else {
                return nil
            }

            let bestSets = recent.compactMap {
                bestSet(
                    from: $0.exercise.sets
                )
            }

            guard bestSets.count == 3 else {
                return nil
            }

            let newest = bestSets[0]
            let previous = bestSets[1]
            let oldest = bestSets[2]

            guard isWorse(
                newest,
                than: previous
            ),
            isWorse(
                previous,
                than: oldest
            ) else {
                return nil
            }

            return RecoveryWarning(
                title:
                    "\(recent[0].exercise.exerciseName) declining",
                message:
                    "Performance declined across the last "
                    + "3 logged sessions.",
                recommendation:
                    "Reduce load by 5–10%, cut 1–2 sets, "
                    + "or add an extra recovery day.",
                severity: .high
            )
        }
        .sorted {
            $0.title < $1.title
        }
    }

    // MARK: - Helpers

    private static func groupPerformancesByExercise(
        logs: [WorkoutLog]
    ) -> [
        String: [
            (
                date: Date,
                exercise: CompletedExercise
            )
        ]
    ] {
        var result: [
            String: [
                (
                    date: Date,
                    exercise: CompletedExercise
                )
            ]
        ] = [:]

        for log in logs {
            for exercise in log.completedExercises {
                let key =
                    exercise.exerciseID?.uuidString
                    ?? exercise.exerciseName

                result[key, default: []].append(
                    (
                        date: log.date,
                        exercise: exercise
                    )
                )
            }
        }

        return result
    }

    private static func bestSet(
        from sets: [LoggedSet]
    ) -> LoggedSet? {
        sets.max { first, second in
            if first.weight != second.weight {
                return first.weight < second.weight
            }

            return first.reps < second.reps
        }
    }

    private static func isWorse(
        _ newSet: LoggedSet,
        than oldSet: LoggedSet
    ) -> Bool {
        if newSet.weight < oldSet.weight {
            return true
        }

        if newSet.weight == oldSet.weight,
           newSet.reps < oldSet.reps {
            return true
        }

        return false
    }
}
