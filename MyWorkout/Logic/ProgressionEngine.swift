import Foundation

struct ProgressionSuggestion {
    let exerciseName: String
    let currentWeight: Double
    let suggestedWeight: Double
    let message: String
}

struct ProgressionEngine {
    static func suggestion(
        exercise: Exercise,
        currentSets: [LoggedSet],
        previousPerformances: [CompletedExercise]
    ) -> ProgressionSuggestion? {
        switch exercise.progressionStrategy {
        case .doubleProgression:
            return doubleProgressionSuggestion(
                exercise: exercise,
                currentSets: currentSets,
                previousPerformances: previousPerformances
            )

        case .slowProgression:
            return slowProgressionSuggestion(
                exercise: exercise,
                currentSets: currentSets,
                previousPerformances: previousPerformances
            )

        case .repsThenWeight:
            return repsThenWeightSuggestion(
                exercise: exercise,
                currentSets: currentSets,
                previousPerformances: previousPerformances
            )

        case .bodyweightReps:
            return bodyweightRepsSuggestion(
                exercise: exercise,
                currentSets: currentSets,
                previousPerformances: previousPerformances
            )
        }
    }

    private static func doubleProgressionSuggestion(
        exercise: Exercise,
        currentSets: [LoggedSet],
        previousPerformances: [CompletedExercise]
    ) -> ProgressionSuggestion? {
        weightedSuggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: previousPerformances,
            successMessage: "Increase next time",
            keepMessage: "Keep same weight",
            deloadMessage: "Deload next time"
        )
    }

    private static func slowProgressionSuggestion(
        exercise: Exercise,
        currentSets: [LoggedSet],
        previousPerformances: [CompletedExercise]
    ) -> ProgressionSuggestion? {
        guard let base = weightedSuggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: previousPerformances,
            successMessage: "Increase carefully next time",
            keepMessage: "Keep same weight",
            deloadMessage: "Deload next time"
        ) else {
            return nil
        }

        if base.suggestedWeight > base.currentWeight {
            let smallerIncrease = max(1, exercise.progressionRule.increaseAmount / 2)

            return ProgressionSuggestion(
                exerciseName: exercise.name,
                currentWeight: base.currentWeight,
                suggestedWeight: base.currentWeight + smallerIncrease,
                message: "Small increase next time"
            )
        }

        return base
    }

    private static func repsThenWeightSuggestion(
        exercise: Exercise,
        currentSets: [LoggedSet],
        previousPerformances: [CompletedExercise]
    ) -> ProgressionSuggestion? {
        guard !currentSets.isEmpty else { return nil }

        let rule = exercise.progressionRule
        let currentWeight = currentSets.last?.weight ?? 0
        let workingSets = currentSets.filter { $0.weight == currentWeight }

        let allSetsHitMax = !workingSets.isEmpty && workingSets.allSatisfy {
            $0.reps >= rule.maxReps
        }

        if allSetsHitMax {
            return ProgressionSuggestion(
                exerciseName: exercise.name,
                currentWeight: currentWeight,
                suggestedWeight: currentWeight + rule.increaseAmount,
                message: "All reps reached — increase weight next time"
            )
        }

        return ProgressionSuggestion(
            exerciseName: exercise.name,
            currentWeight: currentWeight,
            suggestedWeight: currentWeight,
            message: "Add reps before increasing weight"
        )
    }

    private static func bodyweightRepsSuggestion(
        exercise: Exercise,
        currentSets: [LoggedSet],
        previousPerformances: [CompletedExercise]
    ) -> ProgressionSuggestion? {
        guard !currentSets.isEmpty else { return nil }

        let rule = exercise.progressionRule
        let currentWeight = currentSets.last?.weight ?? 0

        let allSetsHitMax = currentSets.allSatisfy {
            $0.reps >= rule.maxReps
        }

        if allSetsHitMax {
            return ProgressionSuggestion(
                exerciseName: exercise.name,
                currentWeight: currentWeight,
                suggestedWeight: currentWeight + rule.increaseAmount,
                message: "Add external load next time"
            )
        }

        let repeatedFailures = previousPerformances
            .prefix(rule.stallLimit - 1)
            .allSatisfy { performance in
                performance.sets.contains { $0.reps < rule.minReps }
            }

        let currentBelowMinimum = currentSets.contains {
            $0.reps < rule.minReps
        }

        if currentBelowMinimum &&
            previousPerformances.count >= rule.stallLimit - 1 &&
            repeatedFailures {
            return ProgressionSuggestion(
                exerciseName: exercise.name,
                currentWeight: currentWeight,
                suggestedWeight: currentWeight,
                message: "Use assistance or reduce target reps"
            )
        }

        return ProgressionSuggestion(
            exerciseName: exercise.name,
            currentWeight: currentWeight,
            suggestedWeight: currentWeight,
            message: "Add reps before adding weight"
        )
    }

    private static func weightedSuggestion(
        exercise: Exercise,
        currentSets: [LoggedSet],
        previousPerformances: [CompletedExercise],
        successMessage: String,
        keepMessage: String,
        deloadMessage: String
    ) -> ProgressionSuggestion? {
        guard !currentSets.isEmpty else { return nil }

        let rule = exercise.progressionRule
        let currentWeight = currentSets.last?.weight ?? 0
        let workingSets = currentSets.filter { $0.weight == currentWeight }

        let allSetsHitMax = !workingSets.isEmpty && workingSets.allSatisfy {
            $0.reps >= rule.maxReps
        }

        if allSetsHitMax {
            return ProgressionSuggestion(
                exerciseName: exercise.name,
                currentWeight: currentWeight,
                suggestedWeight: currentWeight + rule.increaseAmount,
                message: successMessage
            )
        }

        let failedCurrent = workingSets.contains {
            $0.reps < rule.maxReps
        }

        let previousFailuresSameWeight = previousPerformances
            .prefix(rule.stallLimit - 1)
            .allSatisfy { performance in
                let setsAtWeight = performance.sets.filter { $0.weight == currentWeight }

                return !setsAtWeight.isEmpty && setsAtWeight.contains {
                    $0.reps < rule.maxReps
                }
            }

        if failedCurrent &&
            previousPerformances.count >= rule.stallLimit - 1 &&
            previousFailuresSameWeight {
            return ProgressionSuggestion(
                exerciseName: exercise.name,
                currentWeight: currentWeight,
                suggestedWeight: max(0, currentWeight - rule.deloadAmount),
                message: deloadMessage
            )
        }

        return ProgressionSuggestion(
            exerciseName: exercise.name,
            currentWeight: currentWeight,
            suggestedWeight: currentWeight,
            message: keepMessage
        )
    }
}
