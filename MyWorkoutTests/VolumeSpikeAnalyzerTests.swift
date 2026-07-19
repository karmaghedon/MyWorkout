import XCTest
@testable import MyWorkout

final class VolumeSpikeAnalyzerTests: XCTestCase {

    private let now = Date(
        timeIntervalSince1970: 2_000_000_000
    )

    private var calendar: Calendar {
        var calendar = Calendar(
            identifier: .gregorian
        )
        calendar.timeZone = TimeZone(
            secondsFromGMT: 0
        )!
        return calendar
    }

    // MARK: - Empty and Baseline Cases

    func testNoLogsProducesNoWarnings() {
        let warnings = VolumeSpikeAnalyzer.warnings(
            logs: [],
            registry: makeRegistry(),
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    func testCurrentWeekVolumeWithoutPreviousWeekBaselineProducesNoWarning() {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                setCount: 12
            )
        ]

        let warnings = VolumeSpikeAnalyzer.warnings(
            logs: logs,
            registry: makeRegistry(
                exercises: [exercise]
            ),
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    func testEqualWeeklyVolumeProducesNoWarning() {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                setCount: 8
            ),
            makeLog(
                daysAgo: 9,
                exercise: exercise,
                setCount: 8
            )
        ]

        let warnings = analyze(
            logs: logs,
            exercises: [exercise]
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    // MARK: - Medium Warning

    func testExactlyFiftyPercentIncreaseWithEightCurrentSetsProducesMediumWarning() {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                setCount: 9
            ),
            makeLog(
                daysAgo: 9,
                exercise: exercise,
                setCount: 6
            )
        ]

        guard let warning = analyze(
            logs: logs,
            exercises: [exercise]
        ).first else {
            XCTFail("Expected warning")
            return
        }

        XCTAssertEqual(
            warning.title,
            "Chest volume spike"
        )
        XCTAssertEqual(
            warning.message,
            "Volume increased from 6 to 9 sets this week."
        )
        XCTAssertEqual(
            warning.severity,
            .medium
        )
    }

    func testFiftyPercentIncreaseBelowEightCurrentSetsProducesNoWarning() {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                setCount: 6
            ),
            makeLog(
                daysAgo: 9,
                exercise: exercise,
                setCount: 4
            )
        ]

        let warnings = analyze(
            logs: logs,
            exercises: [exercise]
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    func testIncreaseBelowFiftyPercentProducesNoWarning() {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                setCount: 11
            ),
            makeLog(
                daysAgo: 9,
                exercise: exercise,
                setCount: 8
            )
        ]

        let warnings = analyze(
            logs: logs,
            exercises: [exercise]
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    // MARK: - High Warning

    func testExactlyDoubleVolumeProducesHighWarning() throws {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                setCount: 8
            ),
            makeLog(
                daysAgo: 9,
                exercise: exercise,
                setCount: 4
            )
        ]

        let warning = try XCTUnwrap(
            analyze(
                logs: logs,
                exercises: [exercise]
            ).first
        )

        XCTAssertEqual(
            warning.title,
            "Chest volume spike"
        )
        XCTAssertEqual(
            warning.message,
            "Volume doubled from 4 to 8 sets this week."
        )
        XCTAssertEqual(
            warning.severity,
            .high
        )
    }

    func testMoreThanDoubleVolumeProducesHighWarning() throws {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                setCount: 10
            ),
            makeLog(
                daysAgo: 9,
                exercise: exercise,
                setCount: 4
            )
        ]

        let warning = try XCTUnwrap(
            analyze(
                logs: logs,
                exercises: [exercise]
            ).first
        )

        XCTAssertEqual(
            warning.severity,
            .high
        )
    }

    // MARK: - Aggregation

    func testVolumeAggregatesAcrossMultipleWorkoutsForSameMuscleGroup() throws {
        let benchPress = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )
        let inclinePress = makeExercise(
            name: "Incline Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 1,
                exercise: benchPress,
                setCount: 4
            ),
            makeLog(
                daysAgo: 3,
                exercise: inclinePress,
                setCount: 5
            ),
            makeLog(
                daysAgo: 9,
                exercise: benchPress,
                setCount: 6
            )
        ]

        let warning = try XCTUnwrap(
            analyze(
                logs: logs,
                exercises: [
                    benchPress,
                    inclinePress
                ]
            ).first
        )

        XCTAssertEqual(
            warning.message,
            "Volume increased from 6 to 9 sets this week."
        )
        XCTAssertEqual(
            warning.severity,
            .medium
        )
    }

    func testDifferentMuscleGroupsAreAnalyzedIndependently() {
        let benchPress = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )
        let row = makeExercise(
            name: "Row",
            muscleGroup: .back
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: benchPress,
                setCount: 8
            ),
            makeLog(
                daysAgo: 9,
                exercise: benchPress,
                setCount: 4
            ),
            makeLog(
                daysAgo: 2,
                exercise: row,
                setCount: 9
            ),
            makeLog(
                daysAgo: 9,
                exercise: row,
                setCount: 6
            )
        ]

        let warnings = analyze(
            logs: logs,
            exercises: [
                benchPress,
                row
            ]
        )

        XCTAssertEqual(
            warnings.map(\.title),
            [
                "Back volume spike",
                "Chest volume spike"
            ]
        )
        XCTAssertEqual(
            warnings.map(\.severity),
            [
                .medium,
                .high
            ]
        )
    }

    // MARK: - Exercise Resolution

    func testExerciseResolvesByIdentifierWhenLoggedNameChanged() throws {
        let exerciseID = UUID()
        let exercise = makeExercise(
            id: exerciseID,
            name: "Current Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exerciseID: exerciseID,
                exerciseName: "Historical Bench Name",
                setCount: 8
            ),
            makeLog(
                daysAgo: 9,
                exerciseID: exerciseID,
                exerciseName: "Historical Bench Name",
                setCount: 4
            )
        ]

        let warning = try XCTUnwrap(
            analyze(
                logs: logs,
                exercises: [exercise]
            ).first
        )

        XCTAssertEqual(
            warning.title,
            "Chest volume spike"
        )
    }

    func testExerciseResolvesByNormalizedNameWithoutIdentifier() throws {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exerciseID: nil,
                exerciseName: "  bench press  ",
                setCount: 8
            ),
            makeLog(
                daysAgo: 9,
                exerciseID: nil,
                exerciseName: "BENCH PRESS",
                setCount: 4
            )
        ]

        let warning = try XCTUnwrap(
            analyze(
                logs: logs,
                exercises: [exercise]
            ).first
        )

        XCTAssertEqual(
            warning.title,
            "Chest volume spike"
        )
    }

    func testUnresolvedExercisesAreIgnored() {
        let logs = [
            makeLog(
                daysAgo: 2,
                exerciseID: UUID(),
                exerciseName: "Unknown Exercise",
                setCount: 12
            ),
            makeLog(
                daysAgo: 9,
                exerciseID: UUID(),
                exerciseName: "Unknown Exercise",
                setCount: 4
            )
        ]

        let warnings = analyze(
            logs: logs,
            exercises: []
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    // MARK: - Date Boundaries

    func testExactlySevenDaysAgoBelongsToCurrentWeek() throws {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 7,
                exercise: exercise,
                setCount: 8
            ),
            makeLog(
                daysAgo: 10,
                exercise: exercise,
                setCount: 4
            )
        ]

        let warning = try XCTUnwrap(
            analyze(
                logs: logs,
                exercises: [exercise]
            ).first
        )

        XCTAssertEqual(
            warning.severity,
            .high
        )
    }

    func testJustBeforeSevenDayBoundaryBelongsToPreviousWeek() {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let sevenDaysAgo = date(
            daysAgo: 7
        )

        let logs = [
            makeLog(
                date: sevenDaysAgo.addingTimeInterval(1),
                exercise: exercise,
                setCount: 8
            ),
            makeLog(
                date: sevenDaysAgo.addingTimeInterval(-1),
                exercise: exercise,
                setCount: 4
            )
        ]

        let warning = analyze(
            logs: logs,
            exercises: [exercise]
        ).first

        XCTAssertEqual(
            warning?.severity,
            .high
        )
    }

    func testExactlyFourteenDaysAgoBelongsToPreviousWeek() throws {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                setCount: 8
            ),
            makeLog(
                daysAgo: 14,
                exercise: exercise,
                setCount: 4
            )
        ]

        let warning = try XCTUnwrap(
            analyze(
                logs: logs,
                exercises: [exercise]
            ).first
        )

        XCTAssertEqual(
            warning.severity,
            .high
        )
    }

    func testOlderThanFourteenDaysIsIgnored() {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                setCount: 8
            ),
            makeLog(
                date: date(
                    daysAgo: 14
                ).addingTimeInterval(-1),
                exercise: exercise,
                setCount: 4
            )
        ]

        let warnings = analyze(
            logs: logs,
            exercises: [exercise]
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    func testFutureDatedLogsAreIgnored() {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                date: now.addingTimeInterval(60),
                exercise: exercise,
                setCount: 20
            ),
            makeLog(
                daysAgo: 9,
                exercise: exercise,
                setCount: 4
            )
        ]

        let warnings = analyze(
            logs: logs,
            exercises: [exercise]
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    // MARK: - Helpers

    private func analyze(
        logs: [WorkoutLog],
        exercises: [Exercise]
    ) -> [RecoveryWarning] {
        VolumeSpikeAnalyzer.warnings(
            logs: logs,
            registry: makeRegistry(
                exercises: exercises
            ),
            now: now,
            calendar: calendar
        )
    }

    private func makeRegistry(
        exercises: [Exercise] = []
    ) -> ExerciseRegistry {
        ExerciseRegistry(
            sources: [
                TestExerciseProvider(
                    exercises: exercises
                )
            ]
        )
    }

    private func makeExercise(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup
    ) -> Exercise {
        Exercise(
            id: id,
            name: name,
            muscleGroup: muscleGroup,
            equipment: .barbell,
            instructions: "",
            progressionRule: ProgressionRule(
                minReps: 8,
                maxReps: 10,
                increaseAmount: 5,
                deloadAmount: 5,
                stallLimit: 3
            ),
            exerciseType: .compound,
            progressionStrategy: .doubleProgression
        )
    }

    private func makeLog(
        daysAgo: Int,
        exercise: Exercise,
        setCount: Int
    ) -> WorkoutLog {
        makeLog(
            date: date(
                daysAgo: daysAgo
            ),
            exercise: exercise,
            setCount: setCount
        )
    }

    private func makeLog(
        date: Date,
        exercise: Exercise,
        setCount: Int
    ) -> WorkoutLog {
        makeLog(
            date: date,
            exerciseID: exercise.id,
            exerciseName: exercise.name,
            setCount: setCount
        )
    }

    private func makeLog(
        daysAgo: Int,
        exerciseID: UUID?,
        exerciseName: String,
        setCount: Int
    ) -> WorkoutLog {
        makeLog(
            date: date(
                daysAgo: daysAgo
            ),
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            setCount: setCount
        )
    }

    private func makeLog(
        date: Date,
        exerciseID: UUID?,
        exerciseName: String,
        setCount: Int
    ) -> WorkoutLog {
        WorkoutLog(
            workoutName: "Test Workout",
            date: date,
            completedExercises: [
                CompletedExercise(
                    exerciseID: exerciseID,
                    exerciseName: exerciseName,
                    sets: makeSets(
                        count: setCount
                    ),
                    notes: ""
                )
            ]
        )
    }

    private func makeSets(
        count: Int
    ) -> [LoggedSet] {
        (1...count).map {
            LoggedSet(
                setNumber: $0,
                weight: 100,
                reps: 8
            )
        }
    }

    private func date(
        daysAgo: Int
    ) -> Date {
        calendar.date(
            byAdding: .day,
            value: -daysAgo,
            to: now
        )!
    }
}

private struct TestExerciseProvider: ExerciseProviding {
    let exercises: [Exercise]
}
