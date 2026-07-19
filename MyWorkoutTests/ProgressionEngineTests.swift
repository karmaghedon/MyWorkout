import XCTest
@testable import MyWorkout

final class ProgressionEngineTests: XCTestCase {

    // MARK: - No Current Sets

    func testNoCurrentSetsReturnsNilForEveryStrategy() {
        for strategy in ProgressionStrategy.allCases {
            let exercise = makeExercise(strategy: strategy)

            let result = ProgressionEngine.suggestion(
                exercise: exercise,
                currentSets: [],
                previousPerformances: []
            )

            XCTAssertNil(
                result,
                "\(strategy) should return nil with no current sets"
            )
        }
    }

    // MARK: - Double Progression

    func testDoubleProgressionAllSetsAtMaximumSuggestsIncrease() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12,
            increaseAmount: 5
        )

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([12, 12, 12], weight: 100),
            previousPerformances: []
        )

        XCTAssertEqual(result?.exerciseName, exercise.name)
        XCTAssertEqual(result?.currentWeight, 100)
        XCTAssertEqual(result?.suggestedWeight, 105)
        XCTAssertEqual(result?.message, "Increase next time")
    }

    func testDoubleProgressionRepsAboveMaximumAlsoSuggestIncrease() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12,
            increaseAmount: 5
        )

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([13, 12, 14], weight: 100),
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 105)
    }

    func testDoubleProgressionOneSetBelowMaximumKeepsWeight() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12
        )

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([12, 12, 11], weight: 100),
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 100)
        XCTAssertEqual(result?.message, "Keep same weight")
    }

    func testDoubleProgressionRepeatedFailureAtSameWeightSuggestsDeload() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12,
            deloadAmount: 10,
            stallLimit: 3
        )

        let previous = [
            completedExercise([9, 8, 7], weight: 100),
            completedExercise([10, 9, 8], weight: 100)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([9, 8, 7], weight: 100),
            previousPerformances: previous
        )

        XCTAssertEqual(result?.suggestedWeight, 90)
        XCTAssertEqual(result?.message, "Deload next time")
    }

    func testDoubleProgressionInsufficientFailureHistoryDoesNotDeload() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12,
            deloadAmount: 10,
            stallLimit: 3
        )

        let previous = [
            completedExercise([9, 8, 7], weight: 100)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([9, 8, 7], weight: 100),
            previousPerformances: previous
        )

        XCTAssertEqual(result?.suggestedWeight, 100)
        XCTAssertEqual(result?.message, "Keep same weight")
    }

    func testDoubleProgressionFailuresAtDifferentWeightDoNotDeload() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12,
            deloadAmount: 10,
            stallLimit: 3
        )

        let previous = [
            completedExercise([9, 8, 7], weight: 95),
            completedExercise([9, 8, 7], weight: 95)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([9, 8, 7], weight: 100),
            previousPerformances: previous
        )

        XCTAssertEqual(result?.suggestedWeight, 100)
        XCTAssertEqual(result?.message, "Keep same weight")
    }

    func testDoubleProgressionSuccessfulPriorSessionBreaksStallSequence() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12,
            deloadAmount: 10,
            stallLimit: 3
        )

        let previous = [
            completedExercise([9, 8, 7], weight: 100),
            completedExercise([12, 12, 12], weight: 100)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([9, 8, 7], weight: 100),
            previousPerformances: previous
        )

        XCTAssertEqual(result?.suggestedWeight, 100)
        XCTAssertEqual(result?.message, "Keep same weight")
    }

    func testDoubleProgressionUsesLastSetWeightAsWorkingWeight() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12,
            increaseAmount: 5
        )

        let currentSets = [
            LoggedSet(setNumber: 1, weight: 45, reps: 12),
            LoggedSet(setNumber: 2, weight: 100, reps: 12),
            LoggedSet(setNumber: 3, weight: 100, reps: 12)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: []
        )

        XCTAssertEqual(result?.currentWeight, 100)
        XCTAssertEqual(result?.suggestedWeight, 105)
    }

    func testDoubleProgressionDeloadNeverGoesBelowZero() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12,
            deloadAmount: 1_000,
            stallLimit: 2
        )

        let previous = [
            completedExercise([5], weight: 20)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([5], weight: 20),
            previousPerformances: previous
        )

        XCTAssertEqual(result?.suggestedWeight, 0)
    }

    // MARK: - Slow Progression

    func testSlowProgressionAllSetsAtMaximumUsesHalfIncrease() {
        let exercise = makeExercise(
            strategy: .slowProgression,
            maxReps: 12,
            increaseAmount: 10
        )

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([12, 12, 12], weight: 100),
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 105)
        XCTAssertEqual(result?.message, "Small increase next time")
    }

    func testSlowProgressionIncreaseNeverFallsBelowOne() {
        let exercise = makeExercise(
            strategy: .slowProgression,
            maxReps: 12,
            increaseAmount: 1
        )

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([12, 12, 12], weight: 100),
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 101)
    }

    func testSlowProgressionKeepsWeightWhenMaximumNotReached() {
        let exercise = makeExercise(
            strategy: .slowProgression,
            maxReps: 12
        )

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([12, 11, 12], weight: 100),
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 100)
        XCTAssertEqual(result?.message, "Keep same weight")
    }

    func testSlowProgressionUsesStandardDeloadBehavior() {
        let exercise = makeExercise(
            strategy: .slowProgression,
            maxReps: 12,
            deloadAmount: 10,
            stallLimit: 2
        )

        let previous = [
            completedExercise([10, 9, 8], weight: 100)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([10, 9, 8], weight: 100),
            previousPerformances: previous
        )

        XCTAssertEqual(result?.suggestedWeight, 90)
        XCTAssertEqual(result?.message, "Deload next time")
    }

    // MARK: - Reps Then Weight

    func testRepsThenWeightAllSetsAtMaximumIncreasesWeight() {
        let exercise = makeExercise(
            strategy: .repsThenWeight,
            maxReps: 15,
            increaseAmount: 5
        )

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([15, 15], weight: 50),
            previousPerformances: []
        )

        XCTAssertEqual(result?.currentWeight, 50)
        XCTAssertEqual(result?.suggestedWeight, 55)
        XCTAssertEqual(
            result?.message,
            "All reps reached — increase weight next time"
        )
    }

    func testRepsThenWeightOneSetBelowMaximumKeepsWeight() {
        let exercise = makeExercise(
            strategy: .repsThenWeight,
            maxReps: 15
        )

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([15, 14], weight: 50),
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 50)
        XCTAssertEqual(
            result?.message,
            "Add reps before increasing weight"
        )
    }

    func testRepsThenWeightIgnoresEarlierDifferentWeightSets() {
        let exercise = makeExercise(
            strategy: .repsThenWeight,
            maxReps: 15,
            increaseAmount: 5
        )

        let currentSets = [
            LoggedSet(setNumber: 1, weight: 20, reps: 5),
            LoggedSet(setNumber: 2, weight: 50, reps: 15),
            LoggedSet(setNumber: 3, weight: 50, reps: 15)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: []
        )

        XCTAssertEqual(result?.currentWeight, 50)
        XCTAssertEqual(result?.suggestedWeight, 55)
    }

    // MARK: - Bodyweight Reps

    func testBodyweightRepsAllSetsAtMaximumSuggestsExternalLoad() {
        let exercise = makeExercise(
            strategy: .bodyweightReps,
            maxReps: 20,
            increaseAmount: 5
        )

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([20, 20], weight: 0),
            previousPerformances: []
        )

        XCTAssertEqual(result?.currentWeight, 0)
        XCTAssertEqual(result?.suggestedWeight, 5)
        XCTAssertEqual(result?.message, "Add external load next time")
    }

    func testBodyweightRepsAtMinimumDoesNotCountAsFailure() {
        let exercise = makeExercise(
            strategy: .bodyweightReps,
            minReps: 5,
            maxReps: 20,
            stallLimit: 2
        )

        let previous = [
            completedExercise([3, 2], weight: 0)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([5, 5], weight: 0),
            previousPerformances: previous
        )

        XCTAssertEqual(result?.message, "Add reps before adding weight")
    }

    func testBodyweightRepsRepeatedlyBelowMinimumSuggestsAssistance() {
        let exercise = makeExercise(
            strategy: .bodyweightReps,
            minReps: 5,
            maxReps: 20,
            stallLimit: 3
        )

        let previous = [
            completedExercise([3, 2], weight: 0),
            completedExercise([4, 3], weight: 0)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([3, 2], weight: 0),
            previousPerformances: previous
        )

        XCTAssertEqual(result?.suggestedWeight, 0)
        XCTAssertEqual(
            result?.message,
            "Use assistance or reduce target reps"
        )
    }

    func testBodyweightRepsInsufficientFailureHistoryAddsReps() {
        let exercise = makeExercise(
            strategy: .bodyweightReps,
            minReps: 5,
            maxReps: 20,
            stallLimit: 3
        )

        let previous = [
            completedExercise([3, 2], weight: 0)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([3, 2], weight: 0),
            previousPerformances: previous
        )

        XCTAssertEqual(result?.message, "Add reps before adding weight")
    }

    func testBodyweightRepsSuccessfulPriorSessionBreaksFailureSequence() {
        let exercise = makeExercise(
            strategy: .bodyweightReps,
            minReps: 5,
            maxReps: 20,
            stallLimit: 3
        )

        let previous = [
            completedExercise([3, 2], weight: 0),
            completedExercise([5, 5], weight: 0)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([3, 2], weight: 0),
            previousPerformances: previous
        )

        XCTAssertEqual(result?.message, "Add reps before adding weight")
    }

    func testBodyweightRepsNormalProgressSuggestsAddingReps() {
        let exercise = makeExercise(
            strategy: .bodyweightReps,
            minReps: 5,
            maxReps: 20
        )

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: sets([10, 9], weight: 0),
            previousPerformances: []
        )

        XCTAssertEqual(result?.message, "Add reps before adding weight")
    }

    // MARK: - Fixtures

    private func makeExercise(
        strategy: ProgressionStrategy,
        minReps: Int = 8,
        maxReps: Int = 12,
        increaseAmount: Double = 5,
        deloadAmount: Double = 10,
        stallLimit: Int = 3
    ) -> Exercise {
        Exercise(
            name: "Test Exercise",
            muscleGroup: .chest,
            equipment: .barbell,
            instructions: "Do the thing",
            progressionRule: ProgressionRule(
                minReps: minReps,
                maxReps: maxReps,
                increaseAmount: increaseAmount,
                deloadAmount: deloadAmount,
                stallLimit: stallLimit
            ),
            exerciseType: .compound,
            progressionStrategy: strategy
        )
    }

    private func sets(
        _ reps: [Int],
        weight: Double
    ) -> [LoggedSet] {
        reps.enumerated().map { index, repetitions in
            LoggedSet(
                setNumber: index + 1,
                weight: weight,
                reps: repetitions
            )
        }
    }

    private func completedExercise(
        _ reps: [Int],
        weight: Double
    ) -> CompletedExercise {
        CompletedExercise(
            exerciseName: "Test Exercise",
            sets: sets(reps, weight: weight),
            notes: ""
        )
    }
}
