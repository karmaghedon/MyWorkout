import XCTest
@testable import MyWorkout

final class ProgressionEngineTests: XCTestCase {

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
            muscleGroup: "Chest",
            equipment: "Barbell",
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

    private func sets(_ reps: [Int], weight: Double) -> [LoggedSet] {
        reps.enumerated().map { index, reps in
            LoggedSet(setNumber: index + 1, weight: weight, reps: reps)
        }
    }

    private func completedExercise(_ reps: [Int], weight: Double) -> CompletedExercise {
        CompletedExercise(
            exerciseName: "Test Exercise",
            sets: sets(reps, weight: weight),
            notes: ""
        )
    }

    // MARK: - No current sets

    func test_noCurrentSets_returnsNilForEveryStrategy() {
        for strategy in ProgressionStrategy.allCases {
            let exercise = makeExercise(strategy: strategy)
            let result = ProgressionEngine.suggestion(
                exercise: exercise,
                currentSets: [],
                previousPerformances: []
            )
            XCTAssertNil(result, "\(strategy) should return nil with no current sets")
        }
    }

    // MARK: - Double progression

    func test_doubleProgression_allSetsHitMax_suggestsIncrease() {
        let exercise = makeExercise(strategy: .doubleProgression, maxReps: 12, increaseAmount: 5)
        let currentSets = sets([12, 12, 12], weight: 100)

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 105)
        XCTAssertEqual(result?.currentWeight, 100)
        XCTAssertEqual(result?.message, "Increase next time")
    }

    func test_doubleProgression_belowMaxReps_keepsWeight() {
        let exercise = makeExercise(strategy: .doubleProgression, maxReps: 12)
        let currentSets = sets([10, 9, 8], weight: 100)

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 100)
        XCTAssertEqual(result?.message, "Keep same weight")
    }

    func test_doubleProgression_repeatedFailureAtSameWeight_suggestsDeload() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12,
            deloadAmount: 10,
            stallLimit: 3
        )
        let currentSets = sets([9, 8, 7], weight: 100)
        let previous = [
            completedExercise([9, 8, 7], weight: 100),
            completedExercise([9, 8, 7], weight: 100)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: previous
        )

        XCTAssertEqual(result?.suggestedWeight, 90)
        XCTAssertEqual(result?.message, "Deload next time")
    }

    func test_doubleProgression_deload_neverGoesBelowZero() {
        let exercise = makeExercise(
            strategy: .doubleProgression,
            maxReps: 12,
            deloadAmount: 1000,
            stallLimit: 2
        )
        let currentSets = sets([5], weight: 20)
        let previous = [completedExercise([5], weight: 20)]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: previous
        )

        XCTAssertEqual(result?.suggestedWeight, 0)
    }

    // MARK: - Slow progression

    func test_slowProgression_allSetsHitMax_suggestsSmallerIncrease() {
        let exercise = makeExercise(strategy: .slowProgression, maxReps: 12, increaseAmount: 10)
        let currentSets = sets([12, 12, 12], weight: 100)

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: []
        )

        // Slow progression should halve the standard increase amount (10 / 2 = 5)
        XCTAssertEqual(result?.suggestedWeight, 105)
        XCTAssertEqual(result?.message, "Small increase next time")
    }

    func test_slowProgression_increaseAmount_neverRoundsDownToZero() {
        let exercise = makeExercise(strategy: .slowProgression, maxReps: 12, increaseAmount: 1)
        let currentSets = sets([12, 12, 12], weight: 100)

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: []
        )

        // max(1, 1/2) == 1, so weight should still move up
        XCTAssertEqual(result?.suggestedWeight, 101)
    }

    // MARK: - Reps then weight

    func test_repsThenWeight_allSetsHitMax_increasesWeight() {
        let exercise = makeExercise(strategy: .repsThenWeight, maxReps: 15, increaseAmount: 5)
        let currentSets = sets([15, 15], weight: 50)

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 55)
        XCTAssertEqual(result?.message, "All reps reached — increase weight next time")
    }

    func test_repsThenWeight_belowMaxReps_keepsWeight() {
        let exercise = makeExercise(strategy: .repsThenWeight, maxReps: 15)
        let currentSets = sets([10, 12], weight: 50)

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 50)
        XCTAssertEqual(result?.message, "Add reps before increasing weight")
    }

    // MARK: - Bodyweight reps

    func test_bodyweightReps_allSetsHitMax_suggestsAddingLoad() {
        let exercise = makeExercise(strategy: .bodyweightReps, maxReps: 20, increaseAmount: 5)
        let currentSets = sets([20, 20], weight: 0)

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: []
        )

        XCTAssertEqual(result?.suggestedWeight, 5)
        XCTAssertEqual(result?.message, "Add external load next time")
    }

    func test_bodyweightReps_repeatedlyBelowMinimum_suggestsAssistance() {
        let exercise = makeExercise(
            strategy: .bodyweightReps,
            minReps: 5,
            maxReps: 20,
            stallLimit: 3
        )
        let currentSets = sets([3, 2], weight: 0)
        let previous = [
            completedExercise([3, 2], weight: 0),
            completedExercise([3, 2], weight: 0)
        ]

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: previous
        )

        XCTAssertEqual(result?.message, "Use assistance or reduce target reps")
    }

    func test_bodyweightReps_normalProgress_addReps() {
        let exercise = makeExercise(strategy: .bodyweightReps, minReps: 5, maxReps: 20)
        let currentSets = sets([10, 9], weight: 0)

        let result = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: currentSets,
            previousPerformances: []
        )

        XCTAssertEqual(result?.message, "Add reps before adding weight")
    }
}
