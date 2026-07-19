import Foundation

struct IntraWorkoutFatigueAnalyzer {

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

            let fatigueDetectedInAllThree =
                recent.allSatisfy { performance in
                    hasLargeRepDropWithinWorkout(
                        performance.exercise
                    )
                }

            guard fatigueDetectedInAllThree else {
                return nil
            }

            return RecoveryWarning(
                title:
                    "\(recent[0].exercise.exerciseName) "
                    + "set-to-set fatigue",
                message:
                    "Reps dropped significantly within each "
                    + "of the last 3 logged sessions.",
                recommendation:
                    "Consider longer rest periods, reducing "
                    + "load slightly, or reducing one working set.",
                severity: .medium
            )
        }
        .sorted {
            $0.title < $1.title
        }
    }

    // MARK: - Fatigue Detection

    private static func hasLargeRepDropWithinWorkout(
        _ exercise: CompletedExercise
    ) -> Bool {
        let sets = exercise.sets.sorted {
            $0.setNumber < $1.setNumber
        }

        guard sets.count >= 3 else {
            return false
        }

        guard let firstWeight = sets.first?.weight else {
            return false
        }

        let sameWeightSets = sets.filter {
            $0.weight == firstWeight
        }

        guard sameWeightSets.count >= 3,
              let first = sameWeightSets.first,
              let last = sameWeightSets.last else {
            return false
        }

        return first.reps - last.reps >= 3
    }

    // MARK: - Grouping

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
}
