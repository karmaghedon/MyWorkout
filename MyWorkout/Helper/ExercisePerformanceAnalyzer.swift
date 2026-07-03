import Foundation

struct ExercisePerformanceWarning: Identifiable {
    let id = UUID()
    let exerciseName: String
    let message: String
    let recommendation: String
}

struct ExercisePerformanceAnalyzer {
    static func warnings(logs: [WorkoutLog]) -> [ExercisePerformanceWarning] {
        let grouped = groupPerformancesByExercise(logs: logs)

        return grouped.compactMap { _, performances in
            plateauWarning(for: performances)
        }
        .sorted { $0.exerciseName < $1.exerciseName }
    }

    private static func groupPerformancesByExercise(
        logs: [WorkoutLog]
    ) -> [String: [(date: Date, exercise: CompletedExercise)]] {
        var result: [String: [(date: Date, exercise: CompletedExercise)]] = [:]

        for log in logs {
            for exercise in log.completedExercises {
                let key = exercise.exerciseID?.uuidString ?? exercise.exerciseName
                result[key, default: []].append((date: log.date, exercise: exercise))
            }
        }

        return result
    }

    private static func plateauWarning(
        for performances: [(date: Date, exercise: CompletedExercise)]
    ) -> ExercisePerformanceWarning? {
        let sorted = performances.sorted { $0.date > $1.date }
        let recent = Array(sorted.prefix(3))

        guard recent.count == 3 else { return nil }

        let bestRecentSets = recent.compactMap {
            bestSet(from: $0.exercise.sets)
        }

        guard bestRecentSets.count == 3 else { return nil }

        let newest = bestRecentSets[0]
        let previousOne = bestRecentSets[1]
        let previousTwo = bestRecentSets[2]

        let improvedOverPreviousOne = isBetter(newest, than: previousOne)
        let improvedOverPreviousTwo = isBetter(newest, than: previousTwo)

        if !improvedOverPreviousOne && !improvedOverPreviousTwo {
            return ExercisePerformanceWarning(
                exerciseName: recent[0].exercise.exerciseName,
                message: "Possible plateau: no improvement across the last 3 logged sessions.",
                recommendation: "Keep the same load for one more session, reduce volume slightly, or consider a small deload if effort feels high."
            )
        }

        return nil
    }

    private static func bestSet(from sets: [LoggedSet]) -> LoggedSet? {
        sets.max { first, second in
            if first.weight != second.weight {
                return first.weight < second.weight
            }

            return first.reps < second.reps
        }
    }

    private static func isBetter(_ newSet: LoggedSet, than oldSet: LoggedSet) -> Bool {
        if newSet.weight > oldSet.weight {
            return true
        }

        if newSet.weight == oldSet.weight && newSet.reps > oldSet.reps {
            return true
        }

        return false
    }
}
