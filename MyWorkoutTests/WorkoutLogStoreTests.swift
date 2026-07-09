import XCTest
@testable import MyWorkout

@MainActor
final class WorkoutLogStoreTests: XCTestCase {

    var sut: WorkoutLogStore!

    override func setUp() async throws {
        sut = WorkoutLogStore()
        // Clear any existing logs
        sut.replaceAll(with: [])
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Basic Operations

    func test_initialState_hasNoLogs() {
        XCTAssertEqual(sut.logs.count, 0)
    }

    func test_add_insertsLogAtBeginning() {
        let log = createSampleLog(name: "Push Day")

        sut.add(log)

        XCTAssertEqual(sut.logs.count, 1)
        XCTAssertEqual(sut.logs.first?.workoutName, "Push Day")
    }

    func test_add_multipleLogsAreInReverseChronologicalOrder() {
        let log1 = createSampleLog(name: "Day 1")
        let log2 = createSampleLog(name: "Day 2")

        sut.add(log1)
        sut.add(log2)

        XCTAssertEqual(sut.logs.count, 2)
        XCTAssertEqual(sut.logs[0].workoutName, "Day 2")
        XCTAssertEqual(sut.logs[1].workoutName, "Day 1")
    }

    func test_replaceAll_replacesExistingLogs() {
        sut.add(createSampleLog(name: "Old"))

        let newLogs = [
            createSampleLog(name: "New 1"),
            createSampleLog(name: "New 2")
        ]

        sut.replaceAll(with: newLogs)

        XCTAssertEqual(sut.logs.count, 2)
        XCTAssertEqual(sut.logs[0].workoutName, "New 1")
        XCTAssertEqual(sut.logs[1].workoutName, "New 2")
    }

    // MARK: - Exercise Lookup

    func test_lastPerformance_returnsNilWhenNoLogsExist() {
        let exercise = createSampleExercise(name: "Bench Press")

        let result = sut.lastPerformance(for: exercise)

        XCTAssertNil(result)
    }

    func test_lastPerformance_returnsLastSetFromMostRecentLog() {
        let exercise = createSampleExercise(name: "Bench Press")
        let log = createSampleLog(
            name: "Push",
            exercises: [
                CompletedExercise(
                    exerciseID: exercise.id,
                    exerciseName: "Bench Press",
                    sets: [
                        LoggedSet(setNumber: 1, weight: 135, reps: 10),
                        LoggedSet(setNumber: 2, weight: 155, reps: 8),
                        LoggedSet(setNumber: 3, weight: 175, reps: 6)
                    ],
                    notes: ""
                )
            ]
        )

        sut.add(log)

        let result = sut.lastPerformance(for: exercise)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.weight, 175)
        XCTAssertEqual(result?.reps, 6)
    }

    func test_lastPerformances_returnsRequestedNumberOfPerformances() {
        let exercise = createSampleExercise(name: "Squat")

        for i in 1...5 {
            let log = createSampleLog(
                name: "Leg Day \(i)",
                exercises: [
                    CompletedExercise(
                        exerciseID: exercise.id,
                        exerciseName: "Squat",
                        sets: [LoggedSet(setNumber: 1, weight: Double(100 + i * 10), reps: 8)],
                        notes: ""
                    )
                ]
            )
            sut.add(log)
        }

        let results = sut.lastPerformances(for: exercise, limit: 3)

        XCTAssertEqual(results.count, 3)
        // Most recent first
        XCTAssertEqual(results[0].exerciseName, "Squat")
    }

    func test_lastPerformances_returnsFewerThanRequestedWhenNotEnoughLogs() {
        let exercise = createSampleExercise(name: "Deadlift")
        let log = createSampleLog(
            name: "Pull Day",
            exercises: [
                CompletedExercise(
                    exerciseID: exercise.id,
                    exerciseName: "Deadlift",
                    sets: [LoggedSet(setNumber: 1, weight: 315, reps: 5)],
                    notes: ""
                )
            ]
        )

        sut.add(log)

        let results = sut.lastPerformances(for: exercise, limit: 5)

        XCTAssertEqual(results.count, 1)
    }

    // MARK: - Progression Suggestions

    func test_suggestedStartingSet_returnsNilWhenNoHistory() {
        let exercise = createSampleExercise(name: "Overhead Press")

        let result = sut.suggestedStartingSet(for: exercise)

        XCTAssertNil(result)
    }

    func test_suggestedStartingSet_returnsLastSetWhenNoProgressionNeeded() {
        let exercise = createSampleExercise(
            name: "Bench Press",
            progressionRule: ProgressionRule(
                minReps: 5,
                maxReps: 8,
                increaseAmount: 5,
                stallLimit: 3
            )
        )

        let log = createSampleLog(
            name: "Push",
            exercises: [
                CompletedExercise(
                    exerciseID: exercise.id,
                    exerciseName: "Bench Press",
                    sets: [
                        LoggedSet(setNumber: 1, weight: 135, reps: 6),
                        LoggedSet(setNumber: 2, weight: 135, reps: 6)
                    ],
                    notes: ""
                )
            ]
        )

        sut.add(log)

        let result = sut.suggestedStartingSet(for: exercise)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.weight, 135)
        XCTAssertEqual(result?.reps, 6)
    }

    // MARK: - Helper Methods

    private func createSampleExercise(
        name: String,
        progressionRule: ProgressionRule = ProgressionRule(minReps: 5, maxReps: 10, increaseAmount: 5, stallLimit: 3)
    ) -> Exercise {
        Exercise(
            name: name,
            muscleGroup: "Chest",
            equipment: "Barbell",
            instructions: "Test",
            progressionRule: progressionRule,
            exerciseType: .compound,
            progressionStrategy: .doubleProgression
        )
    }

    private func createSampleLog(
        name: String,
        exercises: [CompletedExercise] = []
    ) -> WorkoutLog {
        WorkoutLog(
            workoutName: name,
            date: Date(),
            durationSeconds: 3600,
            completedExercises: exercises
        )
    }
}
