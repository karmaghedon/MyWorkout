import XCTest
@testable import MyWorkout

final class WorkoutSessionEngineTests: XCTestCase {

    // MARK: - Fixtures

    private func exercise(
        name: String = "Bench Press",
        equipment: String = "Barbell",
        exerciseType: ExerciseType = .compound,
        strategy: ProgressionStrategy = .doubleProgression
    ) -> Exercise {
        Exercise(
            name: name,
            muscleGroup: "Chest",
            equipment: equipment,
            instructions: "Push it",
            progressionRule: ProgressionRule(
                minReps: 8,
                maxReps: 12,
                increaseAmount: 5,
                deloadAmount: 10,
                stallLimit: 3
            ),
            exerciseType: exerciseType,
            progressionStrategy: strategy
        )
    }

    private func inventory(barbellWeight: Double = 45) -> EquipmentInventory {
        EquipmentInventory(
            unitSystem: .pounds,
            barbellWeight: barbellWeight,
            plates: [],
            dumbbells: []
        )
    }

    // MARK: - defaultStartingWeight

    func test_defaultStartingWeight_bodyweight_isAlwaysZero() {
        let ex = exercise(equipment: "Barbell", exerciseType: .bodyweight)
        let weight = WorkoutSessionEngine.defaultStartingWeight(for: ex, equipmentInventory: inventory(barbellWeight: 45))
        XCTAssertEqual(weight, 0)
    }

    func test_defaultStartingWeight_barbellCompound_usesInventoryBarbellWeight() {
        let ex = exercise(equipment: "Barbell", exerciseType: .compound)
        let weight = WorkoutSessionEngine.defaultStartingWeight(for: ex, equipmentInventory: inventory(barbellWeight: 45))
        XCTAssertEqual(weight, 45)
    }

    func test_defaultStartingWeight_nonBarbellCompound_isZero() {
        let ex = exercise(equipment: "Cable Machine", exerciseType: .compound)
        let weight = WorkoutSessionEngine.defaultStartingWeight(for: ex, equipmentInventory: inventory(barbellWeight: 45))
        XCTAssertEqual(weight, 0)
    }

    func test_defaultStartingWeight_isolation_followsSameBarbellRule() {
        let ex = exercise(equipment: "Barbell", exerciseType: .isolation)
        let weight = WorkoutSessionEngine.defaultStartingWeight(for: ex, equipmentInventory: inventory(barbellWeight: 45))
        XCTAssertEqual(weight, 45)
    }

    // MARK: - logSet

    func test_logSet_firstSet_startsAtSetNumberOne() {
        var states: [UUID: ExerciseSessionState] = [:]
        let exerciseID = UUID()
        states[exerciseID] = ExerciseSessionState(
            reps: 10,
            workingWeightPounds: 100
        )

        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)

        XCTAssertEqual(states[exerciseID]?.loggedSets.count, 1)
        XCTAssertEqual(states[exerciseID]?.loggedSets.first?.setNumber, 1)
        XCTAssertEqual(states[exerciseID]?.loggedSets.first?.weight, 100)
        XCTAssertEqual(states[exerciseID]?.loggedSets.first?.reps, 10)
    }

    func test_logSet_subsequentSets_incrementSetNumber() {
        var states: [UUID: ExerciseSessionState] = [:]
        let exerciseID = UUID()
        states[exerciseID] = ExerciseSessionState(reps: 8, workingWeightPounds: 100)

        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)
        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)
        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)

        let setNumbers = states[exerciseID]?.loggedSets.map(\.setNumber)
        XCTAssertEqual(setNumbers, [1, 2, 3])
    }

    func test_logSet_missingState_createsDefaultState() {
        var states: [UUID: ExerciseSessionState] = [:]
        let exerciseID = UUID()

        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)

        XCTAssertEqual(states[exerciseID]?.loggedSets.count, 1)
    }

    // MARK: - deleteSet

    func test_deleteSet_removesSetAndRenumbersRemaining() {
        var states: [UUID: ExerciseSessionState] = [:]
        let exerciseID = UUID()
        states[exerciseID] = ExerciseSessionState(
            reps: 10,
            workingWeightPounds: 100
        )

        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)
        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)
        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)

        let firstSetID = states[exerciseID]!.loggedSets[0].id
        WorkoutSessionEngine.deleteSet(setID: firstSetID, for: exerciseID, in: &states)

        let remaining = states[exerciseID]?.loggedSets
        XCTAssertEqual(remaining?.count, 2)
        XCTAssertEqual(remaining?.map(\.setNumber), [1, 2])
    }

    func test_deleteSet_missingExercise_doesNothing() {
        var states: [UUID: ExerciseSessionState] = [:]
        let exerciseID = UUID()

        WorkoutSessionEngine.deleteSet(setID: UUID(), for: exerciseID, in: &states)

        XCTAssertNil(states[exerciseID])
    }

    // MARK: - completedExercises / workoutLog

    func test_completedExercises_excludesExercisesWithNoLoggedSets() {
        let benched = exercise(name: "Bench Press")
        let squats = exercise(name: "Squat")
        let workout = Workout(name: "Push Day", exercises: [benched, squats])

        var states: [UUID: ExerciseSessionState] = [:]
        states[benched.id] = ExerciseSessionState(reps: 10, workingWeightPounds: 100, loggedSets: [
            LoggedSet(setNumber: 1, weight: 100, reps: 10)
        ])
        // squats has no logged sets at all

        let completed = WorkoutSessionEngine.completedExercises(for: workout, states: states)

        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.exerciseName, "Bench Press")
    }

    func test_workoutLog_noCompletedExercises_returnsNil() {
        let squats = exercise(name: "Squat")
        let workout = Workout(name: "Leg Day", exercises: [squats])

        let log = WorkoutSessionEngine.workoutLog(
            for: workout,
            states: [:],
            durationSeconds: 600
        )

        XCTAssertNil(log)
    }

    func test_workoutLog_withCompletedExercises_producesLogWithCorrectMetadata() {
        let benched = exercise(name: "Bench Press")
        let workout = Workout(name: "Push Day", exercises: [benched])

        var states: [UUID: ExerciseSessionState] = [:]
        states[benched.id] = ExerciseSessionState(reps: 10, workingWeightPounds: 135, loggedSets: [
            LoggedSet(setNumber: 1, weight: 135, reps: 10)
        ])

        let log = WorkoutSessionEngine.workoutLog(
            for: workout,
            states: states,
            durationSeconds: 1800
        )

        XCTAssertEqual(log?.workoutName, "Push Day")
        XCTAssertEqual(log?.durationSeconds, 1800)
        XCTAssertEqual(log?.completedExercises.count, 1)
        XCTAssertEqual(log?.completedExercises.first?.exerciseName, "Bench Press")
    }

    // MARK: - initialState

    func test_initialState_noHistory_usesDefaultStartingWeightAndMessage() {
        let ex = exercise(equipment: "Barbell", exerciseType: .compound)

        let state = WorkoutSessionEngine.initialState(
            for: ex,
            latestPerformance: nil,
            previousPerformances: [],
            equipmentInventory: inventory(barbellWeight: 45)
        )

        XCTAssertEqual(state.reps, 10)
        XCTAssertEqual(state.workingWeightPounds, 45)
        XCTAssertEqual(state.suggestionMessage, "No history yet")
        XCTAssertTrue(state.loggedSets.isEmpty)
    }

    func test_initialState_withHistory_usesProgressionSuggestion() {
        let ex = exercise(equipment: "Barbell", exerciseType: .compound, strategy: .doubleProgression)

        let latest = CompletedExercise(
            exerciseName: "Bench Press",
            sets: [
                LoggedSet(setNumber: 1, weight: 100, reps: 12),
                LoggedSet(setNumber: 2, weight: 100, reps: 12),
                LoggedSet(setNumber: 3, weight: 100, reps: 12)
            ],
            notes: ""
        )

        let state = WorkoutSessionEngine.initialState(
            for: ex,
            latestPerformance: latest,
            previousPerformances: [],
            equipmentInventory: inventory(barbellWeight: 45)
        )

        // All sets hit max reps (12), so double progression should suggest an increase.
        XCTAssertEqual(state.workingWeightPounds, 105)
        XCTAssertEqual(state.reps, 12)
        XCTAssertEqual(state.suggestionMessage, "Increase next time")
    }
}
