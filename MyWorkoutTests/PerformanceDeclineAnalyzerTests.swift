import XCTest
@testable import MyWorkout

final class PerformanceDeclineAnalyzerTests: XCTestCase {

    // MARK: - Empty and Insufficient History

    func testNoLogsProducesNoWarnings() {
        XCTAssertTrue(
            PerformanceDeclineAnalyzer.warnings(logs: []).isEmpty
        )
    }

    func testOneSessionProducesNoWarning() {
        let warnings = PerformanceDeclineAnalyzer.warnings(
            logs: [
                makeLog(
                    daysAgo: 1,
                    exerciseName: "Bench Press",
                    sets: [makeSet(weight: 100, reps: 8)]
                )
            ]
        )

        XCTAssertTrue(warnings.isEmpty)
    }

    func testTwoSessionsProduceNoWarning() {
        let warnings = PerformanceDeclineAnalyzer.warnings(
            logs: [
                makeLog(
                    daysAgo: 1,
                    exerciseName: "Bench Press",
                    sets: [makeSet(weight: 90, reps: 8)]
                ),
                makeLog(
                    daysAgo: 2,
                    exerciseName: "Bench Press",
                    sets: [makeSet(weight: 100, reps: 8)]
                )
            ]
        )

        XCTAssertTrue(warnings.isEmpty)
    }

    func testThreeSessionsWithOneEmptySessionProduceNoWarning() {
        let warnings = PerformanceDeclineAnalyzer.warnings(
            logs: [
                makeLog(
                    daysAgo: 1,
                    exerciseName: "Bench Press",
                    sets: []
                ),
                makeLog(
                    daysAgo: 2,
                    exerciseName: "Bench Press",
                    sets: [makeSet(weight: 95, reps: 8)]
                ),
                makeLog(
                    daysAgo: 3,
                    exerciseName: "Bench Press",
                    sets: [makeSet(weight: 100, reps: 8)]
                )
            ]
        )

        XCTAssertTrue(warnings.isEmpty)
    }

    // MARK: - Decline Detection

    func testDecliningWeightAcrossThreeSessionsProducesHighWarning() throws {
        let warning = try XCTUnwrap(
            PerformanceDeclineAnalyzer.warnings(
                logs: decliningWeightLogs(
                    exerciseName: "Bench Press"
                )
            ).first
        )

        XCTAssertEqual(warning.title, "Bench Press declining")
        XCTAssertEqual(
            warning.message,
            "Performance declined across the last 3 logged sessions."
        )
        XCTAssertEqual(
            warning.recommendation,
            "Reduce load by 5–10%, cut 1–2 sets, or add an extra recovery day."
        )
        XCTAssertEqual(warning.severity, .high)
    }

    func testDecliningRepsAtSameWeightProducesHighWarning() throws {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 100, reps: 6)]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 100, reps: 7)]
            ),
            makeLog(
                daysAgo: 3,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 100, reps: 8)]
            )
        ]

        let warning = try XCTUnwrap(
            PerformanceDeclineAnalyzer.warnings(logs: logs).first
        )

        XCTAssertEqual(warning.title, "Bench Press declining")
        XCTAssertEqual(warning.severity, .high)
    }

    func testMixedWeightAndRepDeclineProducesWarning() throws {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 95, reps: 10)]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 100, reps: 7)]
            ),
            makeLog(
                daysAgo: 3,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 100, reps: 8)]
            )
        ]

        let warning = try XCTUnwrap(
            PerformanceDeclineAnalyzer.warnings(logs: logs).first
        )

        XCTAssertEqual(warning.title, "Bench Press declining")
    }

    // MARK: - No-Warning Cases

    func testEqualPerformanceAcrossThreeSessionsProducesNoWarning() {
        let logs = repeatedLogs(
            exerciseName: "Bench Press",
            weights: [100, 100, 100],
            reps: [8, 8, 8]
        )

        XCTAssertTrue(
            PerformanceDeclineAnalyzer.warnings(logs: logs).isEmpty
        )
    }

    func testImprovingWeightProducesNoWarning() {
        let logs = repeatedLogs(
            exerciseName: "Bench Press",
            weights: [110, 105, 100],
            reps: [8, 8, 8]
        )

        XCTAssertTrue(
            PerformanceDeclineAnalyzer.warnings(logs: logs).isEmpty
        )
    }

    func testImprovingRepsAtSameWeightProducesNoWarning() {
        let logs = repeatedLogs(
            exerciseName: "Bench Press",
            weights: [100, 100, 100],
            reps: [10, 9, 8]
        )

        XCTAssertTrue(
            PerformanceDeclineAnalyzer.warnings(logs: logs).isEmpty
        )
    }

    func testOnlyNewestSessionDeclinesProducesNoWarning() {
        let logs = repeatedLogs(
            exerciseName: "Bench Press",
            weights: [95, 100, 100],
            reps: [8, 8, 8]
        )

        XCTAssertTrue(
            PerformanceDeclineAnalyzer.warnings(logs: logs).isEmpty
        )
    }

    func testPreviousSessionDeclinesButNewestImprovesProducesNoWarning() {
        let logs = repeatedLogs(
            exerciseName: "Bench Press",
            weights: [105, 95, 100],
            reps: [8, 8, 8]
        )

        XCTAssertTrue(
            PerformanceDeclineAnalyzer.warnings(logs: logs).isEmpty
        )
    }

    // MARK: - Best Set Selection

    func testHighestWeightIsSelectedAsBestSetEvenWithFewerReps() throws {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                sets: [
                    makeSet(setNumber: 1, weight: 90, reps: 12),
                    makeSet(setNumber: 2, weight: 95, reps: 5)
                ]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                sets: [
                    makeSet(setNumber: 1, weight: 95, reps: 12),
                    makeSet(setNumber: 2, weight: 100, reps: 5)
                ]
            ),
            makeLog(
                daysAgo: 3,
                exerciseName: "Bench Press",
                sets: [
                    makeSet(setNumber: 1, weight: 100, reps: 12),
                    makeSet(setNumber: 2, weight: 105, reps: 5)
                ]
            )
        ]

        let warning = try XCTUnwrap(
            PerformanceDeclineAnalyzer.warnings(logs: logs).first
        )

        XCTAssertEqual(warning.title, "Bench Press declining")
    }

    func testHigherRepsBreakTieWhenWeightsAreEqual() {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                sets: [
                    makeSet(setNumber: 1, weight: 100, reps: 5),
                    makeSet(setNumber: 2, weight: 100, reps: 8)
                ]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                sets: [
                    makeSet(setNumber: 1, weight: 100, reps: 6),
                    makeSet(setNumber: 2, weight: 100, reps: 8)
                ]
            ),
            makeLog(
                daysAgo: 3,
                exerciseName: "Bench Press",
                sets: [
                    makeSet(setNumber: 1, weight: 100, reps: 7),
                    makeSet(setNumber: 2, weight: 100, reps: 8)
                ]
            )
        ]

        XCTAssertTrue(
            PerformanceDeclineAnalyzer.warnings(logs: logs).isEmpty
        )
    }

    // MARK: - Grouping

    func testExercisesWithDifferentIdentifiersAreAnalyzedIndependently() {
        let benchID = UUID()
        let rowID = UUID()

        let logs = decliningWeightLogs(
            exerciseID: benchID,
            exerciseName: "Bench Press"
        ) + repeatedLogs(
            exerciseID: rowID,
            exerciseName: "Row",
            weights: [110, 105, 100],
            reps: [8, 8, 8]
        )

        XCTAssertEqual(
            PerformanceDeclineAnalyzer.warnings(logs: logs).map(\.title),
            ["Bench Press declining"]
        )
    }

    func testIdentifierGroupingSurvivesExerciseRename() throws {
        let exerciseID = UUID()
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseID: exerciseID,
                exerciseName: "Current Name",
                sets: [makeSet(weight: 90, reps: 8)]
            ),
            makeLog(
                daysAgo: 2,
                exerciseID: exerciseID,
                exerciseName: "Previous Name",
                sets: [makeSet(weight: 95, reps: 8)]
            ),
            makeLog(
                daysAgo: 3,
                exerciseID: exerciseID,
                exerciseName: "Original Name",
                sets: [makeSet(weight: 100, reps: 8)]
            )
        ]

        let warning = try XCTUnwrap(
            PerformanceDeclineAnalyzer.warnings(logs: logs).first
        )

        XCTAssertEqual(warning.title, "Current Name declining")
    }

    func testNameGroupingIsUsedWhenIdentifierIsMissing() throws {
        let warning = try XCTUnwrap(
            PerformanceDeclineAnalyzer.warnings(
                logs: decliningWeightLogs(
                    exerciseID: nil,
                    exerciseName: "Bench Press"
                )
            ).first
        )

        XCTAssertEqual(warning.title, "Bench Press declining")
    }

    func testDifferentNamesWithoutIdentifiersRemainSeparateGroups() {
        let logs = [
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 90, reps: 8)]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 95, reps: 8)]
            ),
            makeLog(
                daysAgo: 3,
                exerciseName: "Barbell Bench Press",
                sets: [makeSet(weight: 100, reps: 8)]
            )
        ]

        XCTAssertTrue(
            PerformanceDeclineAnalyzer.warnings(logs: logs).isEmpty
        )
    }

    // MARK: - Recent History and Ordering

    func testOnlyThreeMostRecentSessionsAreAnalyzed() {
        let logs = decliningWeightLogs(
            exerciseName: "Bench Press"
        ) + [
            makeLog(
                daysAgo: 4,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 90, reps: 8)]
            )
        ]

        XCTAssertEqual(
            PerformanceDeclineAnalyzer.warnings(logs: logs).count,
            1
        )
    }

    func testWarningsAreSortedAlphabeticallyByTitle() {
        let logs = decliningWeightLogs(
            exerciseName: "Row"
        ) + decliningWeightLogs(
            exerciseName: "Bench Press"
        )

        XCTAssertEqual(
            PerformanceDeclineAnalyzer.warnings(logs: logs).map(\.title),
            [
                "Bench Press declining",
                "Row declining"
            ]
        )
    }

    func testFutureDatedLogIsIncludedAsMostRecentHistory() {
        let futureDate = Date(
            timeIntervalSince1970: 2_100_000_000
        )

        let logs = [
            makeLog(
                date: futureDate,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 90, reps: 8)]
            ),
            makeLog(
                daysAgo: 1,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 95, reps: 8)]
            ),
            makeLog(
                daysAgo: 2,
                exerciseName: "Bench Press",
                sets: [makeSet(weight: 100, reps: 8)]
            )
        ]

        XCTAssertEqual(
            PerformanceDeclineAnalyzer.warnings(logs: logs).count,
            1
        )
    }

    // MARK: - Helpers

    private func decliningWeightLogs(
        exerciseID: UUID? = nil,
        exerciseName: String
    ) -> [WorkoutLog] {
        repeatedLogs(
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            weights: [90, 95, 100],
            reps: [8, 8, 8]
        )
    }

    private func repeatedLogs(
        exerciseID: UUID? = nil,
        exerciseName: String,
        weights: [Double],
        reps: [Int]
    ) -> [WorkoutLog] {
        zip(weights, reps).enumerated().map { index, values in
            makeLog(
                daysAgo: index + 1,
                exerciseID: exerciseID,
                exerciseName: exerciseName,
                sets: [
                    makeSet(
                        weight: values.0,
                        reps: values.1
                    )
                ]
            )
        }
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
        makeLog(
            date: date(daysAgo: daysAgo),
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            sets: sets
        )
    }

    private func makeLog(
        date: Date,
        exerciseName: String,
        sets: [LoggedSet]
    ) -> WorkoutLog {
        makeLog(
            date: date,
            exerciseID: nil,
            exerciseName: exerciseName,
            sets: sets
        )
    }

    private func makeLog(
        date: Date,
        exerciseID: UUID?,
        exerciseName: String,
        sets: [LoggedSet]
    ) -> WorkoutLog {
        WorkoutLog(
            workoutName: "Test Workout",
            date: date,
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
        setNumber: Int = 1,
        weight: Double,
        reps: Int
    ) -> LoggedSet {
        LoggedSet(
            setNumber: setNumber,
            weight: weight,
            reps: reps
        )
    }

    private func date(daysAgo: Int) -> Date {
        Date(
            timeIntervalSince1970:
                2_000_000_000
                - Double(daysAgo * 86_400)
        )
    }
}
