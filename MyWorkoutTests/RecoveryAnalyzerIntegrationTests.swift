import XCTest
@testable import MyWorkout

final class RecoveryAnalyzerIntegrationTests: XCTestCase {

    // MARK: - Empty History

    func testEmptyHistoryProducesNoWarnings() {
        let warnings = RecoveryAnalyzer.warnings(
            logs: [],
            registry: makeRegistry()
        )

        XCTAssertTrue(
            warnings.isEmpty
        )
    }

    // MARK: - Individual Analyzer Integration

    func testPerformanceDeclineWarningIsIncluded() throws {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 1,
                exercise: exercise,
                sets: makeSets(
                    weight: 90,
                    reps: [8]
                )
            ),
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                sets: makeSets(
                    weight: 95,
                    reps: [8]
                )
            ),
            makeLog(
                daysAgo: 3,
                exercise: exercise,
                sets: makeSets(
                    weight: 100,
                    reps: [8]
                )
            )
        ]

        let warning = try XCTUnwrap(
            RecoveryAnalyzer.warnings(
                logs: logs,
                registry: makeRegistry(
                    exercises: [exercise]
                )
            ).first
        )

        XCTAssertEqual(
            warning.title,
            "Bench Press declining"
        )
        XCTAssertEqual(
            warning.severity,
            .high
        )
    }

    func testIntraWorkoutFatigueWarningIsIncluded() throws {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 1,
                exercise: exercise,
                sets: makeSets(
                    weight: 100,
                    reps: [10, 8, 7]
                )
            ),
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                sets: makeSets(
                    weight: 100,
                    reps: [10, 8, 7]
                )
            ),
            makeLog(
                daysAgo: 3,
                exercise: exercise,
                sets: makeSets(
                    weight: 100,
                    reps: [10, 8, 7]
                )
            )
        ]

        let warning = try XCTUnwrap(
            RecoveryAnalyzer.warnings(
                logs: logs,
                registry: makeRegistry(
                    exercises: [exercise]
                )
            ).first
        )

        XCTAssertEqual(
            warning.title,
            "Bench Press set-to-set fatigue"
        )
        XCTAssertEqual(
            warning.severity,
            .medium
        )
    }

    func testVolumeSpikeWarningIsIncluded() throws {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                sets: makeSets(
                    weight: 100,
                    reps: Array(
                        repeating: 8,
                        count: 8
                    )
                )
            ),
            makeLog(
                daysAgo: 10,
                exercise: exercise,
                sets: makeSets(
                    weight: 100,
                    reps: Array(
                        repeating: 8,
                        count: 4
                    )
                )
            )
        ]

        let warning = try XCTUnwrap(
            RecoveryAnalyzer.warnings(
                logs: logs,
                registry: makeRegistry(
                    exercises: [exercise]
                )
            ).first
        )

        XCTAssertEqual(
            warning.title,
            "Chest volume spike"
        )
        XCTAssertEqual(
            warning.severity,
            .high
        )
    }

    // MARK: - Combined Analyzer Integration

    func testAllThreeAnalyzerWarningsAreCombined() {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 1,
                exercise: exercise,
                sets: makeSets(
                    weight: 90,
                    reps: [10, 8, 7]
                )
            ),
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                sets: makeSets(
                    weight: 95,
                    reps: [10, 8, 7]
                )
            ),
            makeLog(
                daysAgo: 3,
                exercise: exercise,
                sets: makeSets(
                    weight: 100,
                    reps: [10, 8, 7]
                )
            ),
            makeLog(
                daysAgo: 10,
                exercise: exercise,
                sets: makeSets(
                    weight: 100,
                    reps: [8, 8, 8, 8]
                )
            )
        ]

        let warnings = RecoveryAnalyzer.warnings(
            logs: logs,
            registry: makeRegistry(
                exercises: [exercise]
            )
        )

        XCTAssertEqual(
            warnings.map(\.title),
            [
                "Chest volume spike",
                "Bench Press declining",
                "Bench Press set-to-set fatigue"
            ]
        )
    }

    func testWarningsFromMultipleExercisesAreCombined() {
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
                daysAgo: 1,
                exercise: benchPress,
                sets: makeSets(
                    weight: 90,
                    reps: [8]
                )
            ),
            makeLog(
                daysAgo: 2,
                exercise: benchPress,
                sets: makeSets(
                    weight: 95,
                    reps: [8]
                )
            ),
            makeLog(
                daysAgo: 3,
                exercise: benchPress,
                sets: makeSets(
                    weight: 100,
                    reps: [8]
                )
            ),
            makeLog(
                daysAgo: 1,
                exercise: row,
                sets: makeSets(
                    weight: 100,
                    reps: [10, 8, 7]
                )
            ),
            makeLog(
                daysAgo: 2,
                exercise: row,
                sets: makeSets(
                    weight: 100,
                    reps: [10, 8, 7]
                )
            ),
            makeLog(
                daysAgo: 3,
                exercise: row,
                sets: makeSets(
                    weight: 100,
                    reps: [10, 8, 7]
                )
            )
        ]

        let warnings = RecoveryAnalyzer.warnings(
            logs: logs,
            registry: makeRegistry(
                exercises: [
                    benchPress,
                    row
                ]
            )
        )

        XCTAssertEqual(
            warnings.map(\.title),
            [
                "Bench Press declining",
                "Row set-to-set fatigue"
            ]
        )
    }

    // MARK: - Ordering Contract

    func testFacadePreservesAnalyzerOrdering() {
        let exercise = makeExercise(
            name: "Bench Press",
            muscleGroup: .chest
        )

        let logs = [
            makeLog(
                daysAgo: 1,
                exercise: exercise,
                sets: makeSets(
                    weight: 90,
                    reps: [10, 8, 7]
                )
            ),
            makeLog(
                daysAgo: 2,
                exercise: exercise,
                sets: makeSets(
                    weight: 95,
                    reps: [10, 8, 7]
                )
            ),
            makeLog(
                daysAgo: 3,
                exercise: exercise,
                sets: makeSets(
                    weight: 100,
                    reps: [10, 8, 7]
                )
            ),
            makeLog(
                daysAgo: 10,
                exercise: exercise,
                sets: makeSets(
                    weight: 100,
                    reps: [8, 8, 8, 8]
                )
            )
        ]

        let warnings = RecoveryAnalyzer.warnings(
            logs: logs,
            registry: makeRegistry(
                exercises: [exercise]
            )
        )

        XCTAssertEqual(
            warnings.map(\.title),
            [
                "Chest volume spike",
                "Bench Press declining",
                "Bench Press set-to-set fatigue"
            ]
        )
    }

    // MARK: - Helpers

    private func makeRegistry(
        exercises: [Exercise] = []
    ) -> ExerciseRegistry {
        ExerciseRegistry(
            sources: [
                RecoveryTestExerciseProvider(
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
        sets: [LoggedSet]
    ) -> WorkoutLog {
        WorkoutLog(
            workoutName: "Test Workout",
            date: Date().addingTimeInterval(
                -Double(daysAgo * 86_400)
            ),
            completedExercises: [
                CompletedExercise(
                    exerciseID: exercise.id,
                    exerciseName: exercise.name,
                    sets: sets,
                    notes: ""
                )
            ]
        )
    }

    private func makeSets(
        weight: Double,
        reps: [Int]
    ) -> [LoggedSet] {
        reps.enumerated().map {
            LoggedSet(
                setNumber: $0.offset + 1,
                weight: weight,
                reps: $0.element
            )
        }
    }
}

private struct RecoveryTestExerciseProvider:
    ExerciseProviding {

    let exercises: [Exercise]
}
