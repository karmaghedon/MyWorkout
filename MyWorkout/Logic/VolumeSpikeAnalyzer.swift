import Foundation

struct VolumeSpikeAnalyzer {

    static func warnings(
        logs: [WorkoutLog],
        registry: ExerciseRegistry,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [RecoveryWarning] {
        guard let sevenDaysAgo = calendar.date(
            byAdding: .day,
            value: -7,
            to: now
        ),
        let fourteenDaysAgo = calendar.date(
            byAdding: .day,
            value: -14,
            to: now
        ) else {
            return []
        }

        var currentWeekVolume: [String: Int] = [:]
        var previousWeekVolume: [String: Int] = [:]

        for log in logs {
            for completedExercise in log.completedExercises {
                guard let exercise = matchingExercise(
                    for: completedExercise,
                    registry: registry
                ) else {
                    continue
                }

                let setCount = completedExercise.sets.count
                let muscleGroup =
                    exercise.muscleGroup.displayName

                if log.date >= sevenDaysAgo,
                   log.date <= now {
                    currentWeekVolume[
                        muscleGroup,
                        default: 0
                    ] += setCount
                } else if log.date >= fourteenDaysAgo,
                          log.date < sevenDaysAgo {
                    previousWeekVolume[
                        muscleGroup,
                        default: 0
                    ] += setCount
                }
            }
        }

        return currentWeekVolume.compactMap {
            muscleGroup,
            currentSets in

            let previousSets =
                previousWeekVolume[muscleGroup] ?? 0

            guard previousSets > 0 else {
                return nil
            }

            let increaseRatio =
                Double(currentSets - previousSets)
                / Double(previousSets)

            if increaseRatio >= 1.0 {
                return RecoveryWarning(
                    title:
                        "\(muscleGroup) volume spike",
                    message:
                        "Volume doubled from \(previousSets) "
                        + "to \(currentSets) sets this week.",
                    recommendation:
                        "Consider a deload week or reduce "
                        + "1–3 working sets.",
                    severity: .high
                )
            }

            if increaseRatio >= 0.5,
               currentSets >= 8 {
                return RecoveryWarning(
                    title:
                        "\(muscleGroup) volume spike",
                    message:
                        "Volume increased from \(previousSets) "
                        + "to \(currentSets) sets this week.",
                    recommendation:
                        "Monitor soreness, sleep, and performance "
                        + "over the next sessions.",
                    severity: .medium
                )
            }

            return nil
        }
        .sorted {
            $0.title < $1.title
        }
    }

    // MARK: - Exercise Resolution

    private static func matchingExercise(
        for completedExercise: CompletedExercise,
        registry: ExerciseRegistry
    ) -> Exercise? {
        registry.exercise(
            id: completedExercise.exerciseID,
            name: completedExercise.exerciseName
        )
    }
}
