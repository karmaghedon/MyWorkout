import XCTest
@testable import MyWorkout

@MainActor
final class ActiveWorkoutStoreTests:
    XCTestCase {

    // MARK: - Restore

    func testInitializationWithNoSnapshotStartsEmpty() {
        let persistence =
            MockActiveWorkoutPersistence()

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        XCTAssertNil(store.activeWorkout)
        XCTAssertTrue(store.exerciseStates.isEmpty)
        XCTAssertNil(store.startedAt)
        XCTAssertFalse(store.hasActiveWorkout)
        XCTAssertNil(store.persistenceError)
    }

    func testInitializationRestoresPersistedWorkoutState() {
        let workout =
            ActiveWorkoutTestFactory.makeWorkout(
                name: "Restored Workout"
            )

        let exerciseID =
            workout.exercises.first?.id
            ?? UUID()

        let state = ExerciseSessionState(
            targetReps: 8,
            workingWeightPounds: 135,
            loggedSets: [],
            suggestionMessage: "Keep going",
            notes: "Restored notes"
        )

        let startedAt = Date()
            .addingTimeInterval(-120)

        let snapshot =
            ActiveWorkoutTestFactory.makeSnapshot(
                workout: workout,
                exerciseStates: [
                    exerciseID: state
                ],
                startedAt: startedAt
            )

        let persistence =
            MockActiveWorkoutPersistence(
                loadResult: .success(snapshot)
            )

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        XCTAssertEqual(
            store.activeWorkout?.id,
            workout.id
        )

        XCTAssertEqual(
            store.activeWorkout?.name,
            "Restored Workout"
        )

        XCTAssertEqual(
            store.exerciseStates[exerciseID]?
                .targetReps,
            8
        )

        XCTAssertEqual(
            store.exerciseStates[exerciseID]?
                .workingWeightPounds,
            135
        )

        XCTAssertEqual(
            store.exerciseStates[exerciseID]?
                .notes,
            "Restored notes"
        )

        XCTAssertEqual(
            store.startedAt,
            startedAt
        )

        XCTAssertTrue(store.hasActiveWorkout)
        XCTAssertNil(store.persistenceError)
        XCTAssertEqual(
            persistence.saveCallCount,
            0
        )
    }

    func testInitializationRestoresRestTimerState() {
        let workout =
            ActiveWorkoutTestFactory.makeWorkout()

        let exerciseID =
            workout.exercises.first?.id
            ?? UUID()

        let restStartedAt = Date()

        let snapshot =
            ActiveWorkoutTestFactory.makeSnapshot(
                workout: workout,
                activeRestExerciseID:
                    exerciseID,
                restStartedAt:
                    restStartedAt,
                restTotalSeconds: 120
            )

        let persistence =
            MockActiveWorkoutPersistence(
                loadResult: .success(snapshot)
            )

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        XCTAssertEqual(
            store.activeRestExerciseID,
            exerciseID
        )

        XCTAssertEqual(
            store.restStartedAt,
            restStartedAt
        )

        XCTAssertEqual(
            store.restTotalSeconds,
            120
        )

        XCTAssertGreaterThan(
            store.restSecondsRemaining,
            0
        )
    }

    func testLoadFailureExposesLoadingErrorAndDeletesInvalidPersistence() {
        let persistence =
            MockActiveWorkoutPersistence(
                loadResult: .failure(
                    MockActiveWorkoutPersistence
                        .MockError
                        .loadFailed
                )
            )

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        XCTAssertNil(store.activeWorkout)

        XCTAssertEqual(
            store.persistenceError?.operation,
            .loading
        )

        XCTAssertEqual(
            persistence.deleteCallCount,
            1
        )
    }

    // MARK: - Start

    func testStartPublishesWorkoutAndPersistsSnapshot()
        async {

        let persistence =
            MockActiveWorkoutPersistence()

        let saveExpectation = expectation(
            description:
                "Active workout saved"
        )

        persistence.setOnSave {
            saveExpectation.fulfill()
        }

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        let workout =
            ActiveWorkoutTestFactory.makeWorkout(
                name: "Started Workout"
            )

        let result = store.start(workout)

        await fulfillment(
            of: [saveExpectation],
            timeout: 1
        )

        XCTAssertEqual(
            result,
            .started
        )

        XCTAssertEqual(
            store.activeWorkout?.id,
            workout.id
        )

        XCTAssertTrue(store.hasActiveWorkout)
        XCTAssertNotNil(store.startedAt)

        XCTAssertEqual(
            persistence
                .lastSavedSnapshot?
                .activeWorkout
                .id,
            workout.id
        )
    }

    func testStartDoesNotReplaceExistingActiveWorkout()
        async {

        let persistence =
            MockActiveWorkoutPersistence()

        let saveExpectation = expectation(
            description:
                "Initial workout saved"
        )

        persistence.setOnSave {
            saveExpectation.fulfill()
        }

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        let first =
            ActiveWorkoutTestFactory.makeWorkout(
                name: "First"
            )

        let second =
            ActiveWorkoutTestFactory.makeWorkout(
                name: "Second"
            )

        XCTAssertEqual(
            store.start(first),
            .started
        )

        await fulfillment(
            of: [saveExpectation],
            timeout: 1
        )

        let saveCountAfterFirstStart =
            persistence.saveCallCount

        let secondResult =
            store.start(second)

        await waitForMainActorUpdates()

        XCTAssertEqual(
            secondResult,
            .activeWorkoutAlreadyExists
        )

        XCTAssertEqual(
            store.activeWorkout?.id,
            first.id
        )

        XCTAssertEqual(
            persistence.saveCallCount,
            saveCountAfterFirstStart
        )
    }

    // MARK: - State Persistence

    func testExerciseStateMutationPersistsUpdatedSnapshot()
        async {

        let persistence =
            MockActiveWorkoutPersistence()

        let firstSave = expectation(
            description:
                "Initial snapshot saved"
        )

        persistence.setOnSave {
            firstSave.fulfill()
        }

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        let workout =
            ActiveWorkoutTestFactory.makeWorkout()

        _ = store.start(workout)

        await fulfillment(
            of: [firstSave],
            timeout: 1
        )

        let exerciseID =
            workout.exercises.first?.id
            ?? UUID()

        let updatedSave = expectation(
            description:
                "Updated state saved"
        )

        persistence.setOnSave {
            updatedSave.fulfill()
        }

        store.exerciseStates[exerciseID] =
            ExerciseSessionState(
                targetReps: 6,
                workingWeightPounds: 185,
                notes: "Heavy day"
            )

        await fulfillment(
            of: [updatedSave],
            timeout: 1
        )

        let savedState =
            persistence
                .lastSavedSnapshot?
                .exerciseStates
                .first {
                    $0.exerciseID
                        == exerciseID
                }?
                .state

        XCTAssertEqual(
            savedState?.targetReps,
            6
        )

        XCTAssertEqual(
            savedState?
                .workingWeightPounds,
            185
        )

        XCTAssertEqual(
            savedState?.notes,
            "Heavy day"
        )
    }

    func testStartingRestTimerPersistsRestState()
        async {

        let persistence =
            MockActiveWorkoutPersistence()

        let firstSave = expectation(
            description:
                "Initial snapshot saved"
        )

        persistence.setOnSave {
            firstSave.fulfill()
        }

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        let workout =
            ActiveWorkoutTestFactory.makeWorkout()

        _ = store.start(workout)

        await fulfillment(
            of: [firstSave],
            timeout: 1
        )

        let exerciseID =
            workout.exercises.first?.id
            ?? UUID()

        let restSave = expectation(
            description:
                "Rest state saved"
        )

        persistence.setOnSave {
            restSave.fulfill()
        }

        store.startRestTimer(
            for: exerciseID,
            totalSeconds: 90
        )

        await fulfillment(
            of: [restSave],
            timeout: 1
        )

        XCTAssertEqual(
            store.activeRestExerciseID,
            exerciseID
        )

        XCTAssertEqual(
            store.restTotalSeconds,
            90
        )

        XCTAssertEqual(
            persistence
                .lastSavedSnapshot?
                .activeRestExerciseID,
            exerciseID
        )

        XCTAssertEqual(
            persistence
                .lastSavedSnapshot?
                .restTotalSeconds,
            90
        )
    }

    // MARK: - Clear Lifecycle

    func testCancelClearsStateAndDeletesPersistedWorkout()
        async {

        let persistence =
            MockActiveWorkoutPersistence()

        let firstSave = expectation(
            description:
                "Initial snapshot saved"
        )

        persistence.setOnSave {
            firstSave.fulfill()
        }

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        _ = store.start(
            ActiveWorkoutTestFactory.makeWorkout()
        )

        await fulfillment(
            of: [firstSave],
            timeout: 1
        )

        let deleteExpectation = expectation(
            description:
                "Persistence deleted"
        )

        persistence.setOnDelete {
            deleteExpectation.fulfill()
        }

        store.cancel()

        await fulfillment(
            of: [deleteExpectation],
            timeout: 1
        )

        XCTAssertNil(store.activeWorkout)
        XCTAssertTrue(store.exerciseStates.isEmpty)
        XCTAssertNil(store.startedAt)
        XCTAssertNil(store.activeRestExerciseID)
        XCTAssertEqual(store.elapsedSeconds, 0)
        XCTAssertFalse(store.hasActiveWorkout)
    }

    func testFinishClearsStateAndDeletesPersistedWorkout()
        async {

        let persistence =
            MockActiveWorkoutPersistence()

        let firstSave = expectation(
            description:
                "Initial snapshot saved"
        )

        persistence.setOnSave {
            firstSave.fulfill()
        }

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        _ = store.start(
            ActiveWorkoutTestFactory.makeWorkout()
        )

        await fulfillment(
            of: [firstSave],
            timeout: 1
        )

        let deleteExpectation = expectation(
            description:
                "Persistence deleted"
        )

        persistence.setOnDelete {
            deleteExpectation.fulfill()
        }

        store.finish()

        await fulfillment(
            of: [deleteExpectation],
            timeout: 1
        )

        XCTAssertNil(store.activeWorkout)
        XCTAssertFalse(store.hasActiveWorkout)
        XCTAssertEqual(
            persistence.deleteCallCount,
            1
        )
    }

    func testReplaceActiveWorkoutDeletesOldSessionAndPersistsNewOne()
        async {

        let persistence =
            MockActiveWorkoutPersistence()

        let firstSave = expectation(
            description:
                "First workout saved"
        )

        persistence.setOnSave {
            firstSave.fulfill()
        }

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        _ = store.start(
            ActiveWorkoutTestFactory.makeWorkout(
                name: "Old"
            )
        )

        await fulfillment(
            of: [firstSave],
            timeout: 1
        )

        let deleteExpectation = expectation(
            description:
                "Old session deleted"
        )

        persistence.setOnDelete {
            deleteExpectation.fulfill()
        }

        let replacementSave = expectation(
            description:
                "Replacement saved"
        )

        persistence.setOnSave {
            replacementSave.fulfill()
        }

        let replacement =
            ActiveWorkoutTestFactory.makeWorkout(
                name: "Replacement"
            )

        store.replaceActiveWorkout(
            with: replacement
        )

        await fulfillment(
            of: [
                deleteExpectation,
                replacementSave
            ],
            timeout: 1
        )

        XCTAssertEqual(
            store.activeWorkout?.id,
            replacement.id
        )

        XCTAssertEqual(
            persistence
                .lastSavedSnapshot?
                .activeWorkout
                .id,
            replacement.id
        )
    }

    // MARK: - Errors

    func testSaveFailureExposesSavingError()
        async {

        let persistence =
            MockActiveWorkoutPersistence(
                saveResult: .failure(
                    MockActiveWorkoutPersistence
                        .MockError
                        .saveFailed
                )
            )

        let saveExpectation = expectation(
            description:
                "Failed save attempted"
        )

        persistence.setOnSave {
            saveExpectation.fulfill()
        }

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        _ = store.start(
            ActiveWorkoutTestFactory.makeWorkout()
        )

        await fulfillment(
            of: [saveExpectation],
            timeout: 1
        )

        await waitForMainActorUpdates()

        XCTAssertEqual(
            store.persistenceError?.operation,
            .saving
        )

        XCTAssertNotNil(store.activeWorkout)
    }

    func testSuccessfulSaveClearsPreviousSavingError()
        async {

        let persistence =
            MockActiveWorkoutPersistence(
                saveResult: .failure(
                    MockActiveWorkoutPersistence
                        .MockError
                        .saveFailed
                )
            )

        let firstSave = expectation(
            description:
                "First save fails"
        )

        persistence.setOnSave {
            firstSave.fulfill()
        }

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        let workout =
            ActiveWorkoutTestFactory.makeWorkout()

        _ = store.start(workout)

        await fulfillment(
            of: [firstSave],
            timeout: 1
        )

        await waitForMainActorUpdates()

        XCTAssertEqual(
            store.persistenceError?.operation,
            .saving
        )

        persistence.setSaveResult(
            .success(())
        )

        let secondSave = expectation(
            description:
                "Second save succeeds"
        )

        persistence.setOnSave {
            secondSave.fulfill()
        }

        let exerciseID =
            workout.exercises.first?.id
            ?? UUID()

        store.exerciseStates[exerciseID] =
            ExerciseSessionState(
                targetReps: 9
            )

        await fulfillment(
            of: [secondSave],
            timeout: 1
        )

        await waitForMainActorUpdates()

        XCTAssertNil(store.persistenceError)
    }

    func testDeleteFailureExposesDeletingError()
        async {

        let persistence =
            MockActiveWorkoutPersistence(
                deleteResult: .failure(
                    MockActiveWorkoutPersistence
                        .MockError
                        .deleteFailed
                )
            )

        let firstSave = expectation(
            description:
                "Initial snapshot saved"
        )

        persistence.setOnSave {
            firstSave.fulfill()
        }

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        _ = store.start(
            ActiveWorkoutTestFactory.makeWorkout()
        )

        await fulfillment(
            of: [firstSave],
            timeout: 1
        )

        let deleteExpectation = expectation(
            description:
                "Failed delete attempted"
        )

        persistence.setOnDelete {
            deleteExpectation.fulfill()
        }

        store.cancel()

        await fulfillment(
            of: [deleteExpectation],
            timeout: 1
        )

        await waitForMainActorUpdates()

        XCTAssertEqual(
            store.persistenceError?.operation,
            .deleting
        )
    }

    func testClearPersistenceErrorRemovesCurrentError() {
        let persistence =
            MockActiveWorkoutPersistence(
                loadResult: .failure(
                    MockActiveWorkoutPersistence
                        .MockError
                        .loadFailed
                )
            )

        let store = ActiveWorkoutStore(
            persistence: persistence
        )

        XCTAssertNotNil(
            store.persistenceError
        )

        store.clearPersistenceError()

        XCTAssertNil(
            store.persistenceError
        )
    }

    // MARK: - Formatting

    func testFormatDurationWithoutHours() {
        XCTAssertEqual(
            ActiveWorkoutStore
                .formatDuration(125),
            "02:05"
        )
    }

    func testFormatDurationWithHours() {
        XCTAssertEqual(
            ActiveWorkoutStore
                .formatDuration(3_725),
            "1:02:05"
        )
    }

    // MARK: - Warm-up Checklist

    func testToggleWarmupCompleteTwiceReturnsToOriginalState() {
        let persistence = MockActiveWorkoutPersistence()
        let store = ActiveWorkoutStore(persistence: persistence)
        let exerciseID = UUID()

        store.toggleWarmupComplete(at: 0, weight: 45, reps: 10, for: exerciseID)

        XCTAssertTrue(
            store.exerciseStates[exerciseID]?
                .completedWarmupKeys
                .contains(ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 10)) ?? false
        )

        store.toggleWarmupComplete(at: 0, weight: 45, reps: 10, for: exerciseID)

        XCTAssertFalse(
            store.exerciseStates[exerciseID]?
                .completedWarmupKeys
                .contains(ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 10)) ?? true
        )
    }

    /// Regression test: `WarmupEngine`'s barbell ramp starts with two sets
    /// at the same empty-bar weight (10 reps, then 8) — a weight-only key
    /// would mark both complete from a single tap. Confirms toggling the
    /// 10-rep set at 45 doesn't also complete the 8-rep set at the same
    /// weight, and that a genuinely different weight stays independent too.
    func testToggleWarmupCompleteOnlyAffectsToggledWeightAndRepsPair() {
        let persistence = MockActiveWorkoutPersistence()
        let store = ActiveWorkoutStore(persistence: persistence)
        let exerciseID = UUID()

        store.toggleWarmupComplete(at: 0, weight: 45, reps: 10, for: exerciseID)
        store.toggleWarmupComplete(at: 1, weight: 95, reps: 5, for: exerciseID)
        store.toggleWarmupComplete(at: 1, weight: 95, reps: 5, for: exerciseID)

        let completed =
            store.exerciseStates[exerciseID]?
                .completedWarmupKeys
                ?? []

        XCTAssertEqual(completed, [ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 10)])
        XCTAssertFalse(
            completed.contains(ExerciseSessionState.warmupKey(index: 1, weight: 45, reps: 8))
        )
    }

    /// Regression test for the bug this milestone fixed: "Add Warm-up Set"
    /// seeds the new row from the previous row's weight/reps, so right
    /// after adding one, two rows briefly share an identical weight+reps
    /// pair. A content-only key would mark both complete the moment either
    /// one was checked. Confirms checking the original (lower-index) row
    /// leaves the newly-added duplicate (higher-index) row unchecked.
    func testToggleWarmupCompleteDoesNotAffectDuplicateWeightAndRepsAtDifferentIndex() {
        let persistence = MockActiveWorkoutPersistence()
        let store = ActiveWorkoutStore(persistence: persistence)
        let exerciseID = UUID()

        // Simulates the last warm-up (index 0) and a freshly-added
        // duplicate of it (index 1) — the exact state right after
        // tapping "Add Warm-up Set".
        store.toggleWarmupComplete(at: 0, weight: 45, reps: 10, for: exerciseID)

        let completed =
            store.exerciseStates[exerciseID]?
                .completedWarmupKeys
                ?? []

        XCTAssertTrue(completed.contains(ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 10)))
        XCTAssertFalse(completed.contains(ExerciseSessionState.warmupKey(index: 1, weight: 45, reps: 10)))
    }

    // MARK: - Extra Working Sets

    func testAddExtraSetIncrementsOnlyTargetedExercise() {
        let persistence = MockActiveWorkoutPersistence()
        let store = ActiveWorkoutStore(persistence: persistence)
        let exerciseID = UUID()
        let otherExerciseID = UUID()

        store.addExtraSet(for: exerciseID)

        XCTAssertEqual(
            store.exerciseStates[exerciseID]?.extraWorkingSets,
            1
        )

        XCTAssertNil(store.exerciseStates[otherExerciseID])
    }

    func testAddExtraSetAccumulatesAcrossRepeatedCalls() {
        let persistence = MockActiveWorkoutPersistence()
        let store = ActiveWorkoutStore(persistence: persistence)
        let exerciseID = UUID()

        store.addExtraSet(for: exerciseID)
        store.addExtraSet(for: exerciseID)
        store.addExtraSet(for: exerciseID)

        XCTAssertEqual(
            store.exerciseStates[exerciseID]?.extraWorkingSets,
            3
        )
    }

    // MARK: - Helpers

    private func waitForMainActorUpdates()
        async {

        await Task.yield()
        await Task.yield()
    }
}
