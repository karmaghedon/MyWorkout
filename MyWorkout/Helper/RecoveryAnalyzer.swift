import Foundation

enum WarningSeverity: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct RecoveryWarning: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recommendation: String
    let severity: WarningSeverity
}

struct RecoveryAnalyzer {
    static func warnings(logs: [WorkoutLog]) -> [RecoveryWarning] {
        var warnings: [RecoveryWarning] = []

        warnings.append(contentsOf: volumeSpikeWarnings(logs: logs))
        warnings.append(contentsOf: performanceDeclineWarnings(logs: logs))
        warnings.append(contentsOf: repeatedIntraWorkoutFatigueWarnings(logs: logs))

        return warnings
    }

    private static func repeatedIntraWorkoutFatigueWarnings(logs: [WorkoutLog]) -> [RecoveryWarning] {
        let grouped = groupPerformancesByExercise(logs: logs)

        return grouped.compactMap { _, performances in
            let sorted = performances.sorted { $0.date > $1.date }
            let recent = Array(sorted.prefix(3))

            guard recent.count == 3 else { return nil }

            let fatigueDetectedInAllThree = recent.allSatisfy { performance in
                hasLargeRepDropWithinWorkout(performance.exercise)
            }

            guard fatigueDetectedInAllThree else { return nil }

            return RecoveryWarning(
                title: "\(recent[0].exercise.exerciseName) set-to-set fatigue",
                message: "Reps dropped significantly within each of the last 3 logged sessions.",
                recommendation: "Consider longer rest periods, reducing load slightly, or reducing one working set.",
                severity: .medium
            )
        }
        .sorted { $0.title < $1.title }
    }

    private static func hasLargeRepDropWithinWorkout(_ exercise: CompletedExercise) -> Bool {
        let sets = exercise.sets.sorted { $0.setNumber < $1.setNumber }

        guard let first = sets.first,
              let last = sets.last,
              sets.count >= 3 else {
            return false
        }

        let sameWeightSets = sets.filter { $0.weight == first.weight }

        guard sameWeightSets.count >= 3 else {
            return false
        }

        let repDrop = first.reps - last.reps

        return repDrop >= 3
    }

    private static func volumeSpikeWarnings(logs: [WorkoutLog]) -> [RecoveryWarning] {
        let calendar = Calendar.current
        let now = Date()

        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now),
              let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now) else {
            return []
        }

        var currentWeekVolume: [String: Int] = [:]
        var previousWeekVolume: [String: Int] = [:]

        for log in logs {
            for completedExercise in log.completedExercises {
                guard let exercise = matchingExercise(for: completedExercise) else {
                    continue
                }

                let setCount = completedExercise.sets.count

                if log.date >= sevenDaysAgo {
                    currentWeekVolume[exercise.muscleGroup, default: 0] += setCount
                } else if log.date >= fourteenDaysAgo && log.date < sevenDaysAgo {
                    previousWeekVolume[exercise.muscleGroup, default: 0] += setCount
                }
            }
        }

        return currentWeekVolume.compactMap { muscleGroup, currentSets in
            let previousSets = previousWeekVolume[muscleGroup] ?? 0
            guard previousSets > 0 else { return nil }

            let increaseRatio = Double(currentSets - previousSets) / Double(previousSets)

            if increaseRatio >= 1.0 {
                return RecoveryWarning(
                    title: "\(muscleGroup) volume spike",
                    message: "Volume doubled from \(previousSets) to \(currentSets) sets this week.",
                    recommendation: "Consider a deload week or reduce 1–3 working sets.",
                    severity: .high
                )
            }

            if increaseRatio >= 0.5 && currentSets >= 8 {
                return RecoveryWarning(
                    title: "\(muscleGroup) volume spike",
                    message: "Volume increased from \(previousSets) to \(currentSets) sets this week.",
                    recommendation: "Monitor soreness, sleep, and performance over the next sessions.",
                    severity: .medium
                )
            }

            return nil
        }
        .sorted { $0.title < $1.title }
    }

    private static func performanceDeclineWarnings(logs: [WorkoutLog]) -> [RecoveryWarning] {
        let grouped = groupPerformancesByExercise(logs: logs)

        return grouped.compactMap { _, performances in
            let sorted = performances.sorted { $0.date > $1.date }
            let recent = Array(sorted.prefix(3))

            guard recent.count == 3 else {
                return nil
            }

            let bestSets = recent.compactMap {
                bestSet(from: $0.exercise.sets)
            }

            guard bestSets.count == 3 else {
                return nil
            }

            let newest = bestSets[0]
            let previous = bestSets[1]
            let oldest = bestSets[2]

            let declinedFromPrevious = isWorse(newest, than: previous)
            let previousDeclinedFromOldest = isWorse(previous, than: oldest)

            if declinedFromPrevious && previousDeclinedFromOldest {
                return RecoveryWarning(
                    title: "\(recent[0].exercise.exerciseName) declining",
                    message: "Performance declined across the last 3 logged sessions.",
                    recommendation: "Reduce load by 5–10%, cut 1–2 sets, or add an extra recovery day.",
                    severity: .high
                )
            }

            return nil
        }
        .sorted { $0.title < $1.title }
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

    private static func matchingExercise(for completedExercise: CompletedExercise) -> Exercise? {
        SeedData.exercises.first {
            if let completedID = completedExercise.exerciseID {
                return $0.id == completedID
            }

            return $0.name == completedExercise.exerciseName
        }
    }

    private static func bestSet(from sets: [LoggedSet]) -> LoggedSet? {
        sets.max { first, second in
            if first.weight != second.weight {
                return first.weight < second.weight
            }

            return first.reps < second.reps
        }
    }

    private static func isWorse(_ newSet: LoggedSet, than oldSet: LoggedSet) -> Bool {
        if newSet.weight < oldSet.weight {
            return true
        }

        if newSet.weight == oldSet.weight && newSet.reps < oldSet.reps {
            return true
        }

        return false
    }
}
