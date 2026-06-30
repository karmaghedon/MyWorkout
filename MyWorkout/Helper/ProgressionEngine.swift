import Foundation

struct ProgressionSuggestion {
    let exerciseName: String
    let currentWeight: Int
    let suggestedWeight: Int
    let message: String
}

struct ProgressionEngine {
    static func suggestion(
        exercise: Exercise,
        currentSets: [LoggedSet],
        previousPerformances: [CompletedExercise]
    ) -> ProgressionSuggestion? {
        switch exercise.exerciseType {
        case .compound:
            return weightedSuggestion(
                exercise: exercise,
                currentSets: currentSets,
                previousPerformances: previousPerformances
            )

        case .isolation:
            return weightedSuggestion(
                exercise: exercise,
                currentSets: currentSets,
                previousPerformances: previousPerformances
            )

        case .bodyweight:
            return bodyweightSuggestion(
                exercise: exercise,
                currentSets: currentSets,
                previousPerformances: previousPerformances
            )
        }
    }

    private static func weightedSuggestion(
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
                message: "Increase next time"
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
                message: "Deload next time"
            )
        }

        return ProgressionSuggestion(
            exerciseName: exercise.name,
            currentWeight: currentWeight,
            suggestedWeight: currentWeight,
            message: "Keep same weight"
        )
    }

    private static func bodyweightSuggestion(
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

        let failedCurrent = currentSets.contains {
            $0.reps < rule.maxReps
        }

        let previousFailures = previousPerformances
            .prefix(rule.stallLimit - 1)
            .allSatisfy { performance in
                performance.sets.contains {
                    $0.reps < rule.maxReps
                }
            }

        if failedCurrent &&
            previousPerformances.count >= rule.stallLimit - 1 &&
            previousFailures {
            return ProgressionSuggestion(
                exerciseName: exercise.name,
                currentWeight: currentWeight,
                suggestedWeight: currentWeight,
                message: "Keep bodyweight; reduce target or use assistance"
            )
        }

        return ProgressionSuggestion(
            exerciseName: exercise.name,
            currentWeight: currentWeight,
            suggestedWeight: currentWeight,
            message: "Keep bodyweight"
        )
    }
}
