import XCTest
@testable import MyWorkout

final class IntraWorkoutFatigueAnalyzerTests: XCTestCase {

    // MARK: - Empty and Insufficient History

    func testNoLogsProducesNoWarnings() {
        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: []
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    func testFewerThanThreeSessionsProducesNoWarning() {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            )
        ]

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    // MARK: - Fatigue Detection

    func testRepDropOfExactlyThreeAcrossThreeSessionsProducesWarning() throws {
        let logs = repeatedFatigueLogs(
            exerciseName: "Bench Press",
            reps: [10, 8, 7]
        )

        let warning = try XCTUnwrap(
            IntraWorkoutFatigueAnalyzer.warnings(
                logs: logs
            ).first
        )

        XCTAssertEqual(
            warning.title,
            "Bench Press set-to-set fatigue"
        )
        XCTAssertEqual(
            warning.message,
            "Reps dropped significantly within each of the last 3 logged sessions."
        )
        XCTAssertEqual(
            warning.recommendation,
            "Consider longer rest periods, reducing load slightly, or reducing one working set."
        )
        XCTAssertEqual(
            warning.severity,
            .medium
        )
    }

    func testRepDropGreaterThanThreeProducesWarning() {
        let logs = repeatedFatigueLogs(
            exerciseName: "Bench Press",
            reps: [12, 9, 7]
        )

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertEqual(
            warnings.count,
            1
        )
    }

    func testRepDropOfTwoProducesNoWarning() {
        let logs = repeatedFatigueLogs(
            exerciseName: "Bench Press",
            reps: [10, 9, 8]
        )

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    func testOnlyTwoOfThreeSessionsShowingFatigueProducesNoWarning() {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 3,
                exerciseName: "Bench Press",
                reps: [10, 9, 8]
            )
        ]

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    // MARK: - Set Requirements

    func testFewerThanThreeSetsInAnyRecentSessionProducesNoWarning() {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                reps: [10, 7]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 3,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            )
        ]

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    func testSetsAreEvaluatedInSetNumberOrder() {
        let logs = (1...3).map { day in
            makeLog(
                daysAgo: day,
                exerciseName: "Bench Press",
                sets: [
                    makeSet(
                        setNumber: 3,
                        weight: 100,
                        reps: 7
                    ),
                    makeSet(
                        setNumber: 1,
                        weight: 100,
                        reps: 10
                    ),
                    makeSet(
                        setNumber: 2,
                        weight: 100,
                        reps: 8
                    )
                ]
            )
        }

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertEqual(
            warnings.count,
            1
        )
    }

    // MARK: - Same-Weight Rule

    func testThreeSameWeightSetsAreRequired() {
        let logs = (1...3).map { day in
            makeLog(
                daysAgo: day,
                exerciseName: "Bench Press",
                sets: [
                    makeSet(
                        setNumber: 1,
                        weight: 100,
                        reps: 10
                    ),
                    makeSet(
                        setNumber: 2,
                        weight: 105,
                        reps: 8
                    ),
                    makeSet(
                        setNumber: 3,
                        weight: 100,
                        reps: 7
                    )
                ]
            )
        }

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    func testOnlySetsMatchingFirstSetWeightAreCompared() {
        let logs = (1...3).map { day in
            makeLog(
                daysAgo: day,
                exerciseName: "Bench Press",
                sets: [
                    makeSet(
                        setNumber: 1,
                        weight: 100,
                        reps: 10
                    ),
                    makeSet(
                        setNumber: 2,
                        weight: 105,
                        reps: 2
                    ),
                    makeSet(
                        setNumber: 3,
                        weight: 100,
                        reps: 8
                    ),
                    makeSet(
                        setNumber: 4,
                        weight: 100,
                        reps: 7
                    )
                ]
            )
        }

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertEqual(
            warnings.count,
            1
        )
    }

    func testDifferentWeightRepDropDoesNotCreateFalsePositive() {
        let logs = (1...3).map { day in
            makeLog(
                daysAgo: day,
                exerciseName: "Bench Press",
                sets: [
                    makeSet(
                        setNumber: 1,
                        weight: 100,
                        reps: 10
                    ),
                    makeSet(
                        setNumber: 2,
                        weight: 105,
                        reps: 7
                    ),
                    makeSet(
                        setNumber: 3,
                        weight: 110,
                        reps: 5
                    )
                ]
            )
        }

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    // MARK: - Grouping

    func testExercisesWithDifferentIdentifiersAreAnalyzedIndependently() {
        let benchID = UUID()
        let rowID = UUID()

        let benchLogs = (1...3).map { day in
            makeLog(
                daysAgo: day,
                exerciseID: benchID,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            )
        }

        let rowLogs = (1...3).map { day in
            makeLog(
                daysAgo: day,
                exerciseID: rowID,
                exerciseName: "Row",
                reps: [10, 9, 8]
            )
        }

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: benchLogs + rowLogs
        )

        XCTAssertEqual(
            warnings.map(\.title),
            ["Bench Press set-to-set fatigue"]
        )
    }

    func testIdentifierGroupingSurvivesExerciseRename() throws {
        let exerciseID = UUID()

        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseID: exerciseID,
                exerciseName: "Current Name",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 2,
                exerciseID: exerciseID,
                exerciseName: "Previous Name",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 3,
                exerciseID: exerciseID,
                exerciseName: "Original Name",
                reps: [10, 8, 7]
            )
        ]

        let warning = try XCTUnwrap(
            IntraWorkoutFatigueAnalyzer.warnings(
                logs: logs
            ).first
        )

        XCTAssertEqual(
            warning.title,
            "Current Name set-to-set fatigue"
        )
    }

    func testNameGroupingIsUsedWhenIdentifierIsMissing() {
        let logs = repeatedFatigueLogs(
            exerciseName: "Bench Press",
            reps: [10, 8, 7]
        )

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertEqual(
            warnings.count,
            1
        )
    }

    func testDifferentNamesWithoutIdentifiersRemainSeparateGroups() {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseID: nil,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 2,
                exerciseID: nil,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 3,
                exerciseID: nil,
                exerciseName: "Barbell Bench Press",
                reps: [10, 8, 7]
            )
        ]

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    // MARK: - Recent History and Ordering

    func testOnlyThreeMostRecentSessionsAreAnalyzed() {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 3,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 4,
                exerciseName: "Bench Press",
                reps: [10, 9, 8]
            )
        ]

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertEqual(
            warnings.count,
            1
        )
    }

    func testOlderFatigueSessionsDoNotTriggerWarningWhenRecentSessionIsStable() {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                reps: [10, 9, 8]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 3,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            ),
            makeLog(
                daysAgo: 4,
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            )
        ]

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    func testWarningsAreSortedAlphabeticallyByTitle() {
        let logs =
            repeatedFatigueLogs(
                exerciseName: "Row",
                reps: [10, 8, 7]
            )
            + repeatedFatigueLogs(
                exerciseName: "Bench Press",
                reps: [10, 8, 7]
            )

        let warnings = IntraWorkoutFatigueAnalyzer.warnings(
            logs: logs
        )

        XCTAssertEqual(
            warnings.map(\.title),
            [
                "Bench Press set-to-set fatigue",
                "Row set-to-set fatigue"
            ]
        )
    }

    // MARK: - Helpers

    private func repeatedFatigueLogs(
        exerciseName: String,
        reps: [Int]
    ) -> [WorkoutLog] {
        (1...3).map { day in
            makeLog(
                daysAgo: day,
                exerciseName: exerciseName,
                reps: reps
            )
        }
    }

    private func makeLog(
        daysAgo: Int,
        exerciseName: String,
        reps: [Int]
    ) -> WorkoutLog {
        makeLog(
            daysAgo: daysAgo,
            exerciseID: nil,
            exerciseName: exerciseName,
            sets: reps.enumerated().map {
                makeSet(
                    setNumber: $0.offset + 1,
                    weight: 100,
                    reps: $0.element
                )
            }
        )
    }

    private func makeLog(
        daysAgo: Int,
        exerciseID: UUID?,
        exerciseName: String,
        reps: [Int]
    ) -> WorkoutLog {
        makeLog(
            daysAgo: daysAgo,
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            sets: reps.enumerated().map {
                makeSet(
                    setNumber: $0.offset + 1,
                    weight: 100,
                    reps: $0.element
                )
            }
        )
    }

    private func makeLog(
        daysAgo: Int,
        exerciseName: String,
        sets: [LoggedSet]
    ) -> WorkoutLog {
        makeLog(
            daysAgo: daysAgo,
            exerciseID: nil,
            exerciseName: exerciseName,
            sets: sets
        )
    }

    private func makeLog(
        daysAgo: Int,
        exerciseID: UUID?,
        exerciseName: String,
        sets: [LoggedSet]
    ) -> WorkoutLog {
        WorkoutLog(
            workoutName: "Test Workout",
            date: date(
                daysAgo: daysAgo
            ),
            completedExercises: [
                CompletedExercise(
                    exerciseID: exerciseID,
                    exerciseName: exerciseName,
                    sets: sets,
                    notes: ""
                )
            ]
        )
    }

    private func makeSet(
        setNumber: Int,
        weight: Double,
        reps: Int
    ) -> LoggedSet {
        LoggedSet(
            setNumber: setNumber,
            weight: weight,
            reps: reps
        )
    }

    private func date(
        daysAgo: Int
    ) -> Date {
        Date(
            timeIntervalSince1970:
                2_000_000_000
                - Double(daysAgo * 86_400)
        )
    }
}
