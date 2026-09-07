import XCTest
@testable import MyWorkout

@MainActor
final class WorkoutLogStoreTests: XCTestCase {

    // MARK: - Loading

    func testInitializationLoadsPersistedLogs() {
        let existingLogs = [
            WorkoutLogTestFactory.make(
                name: "Newest",
                daysAgo: 1
            ),
            WorkoutLogTestFactory.make(
                name: "Older",
                daysAgo: 2
            )
        ]

        let repository = MockWorkoutLogRepository(
            loadResult: .success(existingLogs)
        )

        let store = WorkoutLogStore(
            repository: repository
        )

        XCTAssertEqual(
            store.logs.map(\.workoutName),
            [
                "Newest",
                "Older"
            ]
        )

        XCTAssertNil(
            store.persistenceError
        )
    }

    func testLoadFailureExposesLoadingError() {
        let repository = MockWorkoutLogRepository(
            loadResult: .failure(
                MockWorkoutLogRepository
                    .MockError
                    .loadFailed
            )
        )

        let store = WorkoutLogStore(
            repository: repository
        )

        XCTAssertTrue(
            store.logs.isEmpty
        )

        XCTAssertEqual(
            store.persistenceError?.operation,
            .loading
        )
    }

    // MARK: - Adding

    func testAddInsertsNewestLogAtBeginningAndSavesSnapshot()
        async {

        let repository = MockWorkoutLogRepository(
            loadResult: .success([
                WorkoutLogTestFactory.make(
                    name: "Existing",
                    daysAgo: 2
                )
            ])
        )

        let saveExpectation = expectation(
            description: "Workout history saved"
        )

        repository.setOnSave {
            saveExpectation.fulfill()
        }

        let store = WorkoutLogStore(
            repository: repository
        )

        store.add(
            WorkoutLogTestFactory.make(
                name: "New",
                daysAgo: 1
            )
        )

        await fulfillment(
            of: [saveExpectation],
            timeout: 1
        )

        XCTAssertEqual(
            store.logs.map(\.workoutName),
            [
                "New",
                "Existing"
            ]
        )

        XCTAssertEqual(
            repository
                .lastSavedSnapshot?
                .map(\.workoutName),
            [
                "New",
                "Existing"
            ]
        )
    }

    /// Regression test for the adversarial-review finding that `add()`'s
    /// dispatch to a background save queue isn't otherwise guaranteed
    /// to complete before the process is suspended or killed. Unlike
    /// `testAddInsertsNewestLogAtBeginningAndSavesSnapshot` above
    /// (which waits on an expectation for that background write to
    /// land), this asserts the write has already landed the instant
    /// `flushPendingSave()` returns — no expectation, no waiting.
    func testFlushPendingSaveWaitsForQueuedSaveToComplete() {
        let repository = MockWorkoutLogRepository()
        let store = WorkoutLogStore(repository: repository)

        store.add(
            WorkoutLogTestFactory.make(
                name: "New",
                daysAgo: 0
            )
        )

        store.flushPendingSave()

        XCTAssertEqual(repository.saveCallCount, 1)

        XCTAssertEqual(
            repository
                .lastSavedSnapshot?
                .map(\.workoutName),
            ["New"]
        )
    }

    // MARK: - Replacement

    func testReplaceAllPublishesAndSavesReplacement()
        async {

        let replacement = [
            WorkoutLogTestFactory.make(
                name: "Imported A",
                daysAgo: 1
            ),
            WorkoutLogTestFactory.make(
                name: "Imported B",
                daysAgo: 2
            )
        ]

        let repository = MockWorkoutLogRepository()

        let saveExpectation = expectation(
            description: "Replacement saved"
        )

        repository.setOnSave {
            saveExpectation.fulfill()
        }

        let store = WorkoutLogStore(
            repository: repository
        )

        store.replaceAll(
            with: replacement
        )

        await fulfillment(
            of: [saveExpectation],
            timeout: 1
        )

        XCTAssertEqual(
            store.logs.map(\.workoutName),
            [
                "Imported A",
                "Imported B"
            ]
        )

        XCTAssertEqual(
            repository
                .lastSavedSnapshot?
                .map(\.workoutName),
            [
                "Imported A",
                "Imported B"
            ]
        )
    }

    /// Regression test: a real-world backup import (e.g. a chronological
    /// CSV export converted to WorkoutLog JSON) can hand replaceAll an
    /// oldest-first array. Every other consumer of `logs` — including
    /// `lastPerformances`/`suggestedStartingSet`, which drive the working
    /// weight `WorkoutSessionEngine.initialState` shows at the start of a
    /// session — assumes newest-first without re-sorting themselves, so
    /// an unsorted import silently made the app suggest weight from the
    /// *oldest* matching set instead of the most recent one.
    func testReplaceAllNormalizesOutOfOrderInputToNewestFirst()
        async {

        let oldestFirst = [
            WorkoutLogTestFactory.make(
                name: "Oldest",
                daysAgo: 5
            ),
            WorkoutLogTestFactory.make(
                name: "Middle",
                daysAgo: 3
            ),
            WorkoutLogTestFactory.make(
                name: "Newest",
                daysAgo: 1
            )
        ]

        let repository = MockWorkoutLogRepository()

        let saveExpectation = expectation(
            description: "Replacement saved"
        )

        repository.setOnSave {
            saveExpectation.fulfill()
        }

        let store = WorkoutLogStore(
            repository: repository
        )

        store.replaceAll(
            with: oldestFirst
        )

        await fulfillment(
            of: [saveExpectation],
            timeout: 1
        )

        XCTAssertEqual(
            store.logs.map(\.workoutName),
            [
                "Newest",
                "Middle",
                "Oldest"
            ]
        )
    }

    func testInitializationNormalizesOutOfOrderPersistedLogs() {
        let oldestFirst = [
            WorkoutLogTestFactory.make(
                name: "Oldest",
                daysAgo: 3
            ),
            WorkoutLogTestFactory.make(
                name: "Newest",
                daysAgo: 1
            )
        ]

        let repository = MockWorkoutLogRepository(
            loadResult: .success(oldestFirst)
        )

        let store = WorkoutLogStore(
            repository: repository
        )

        XCTAssertEqual(
            store.logs.map(\.workoutName),
            [
                "Newest",
                "Oldest"
            ]
        )
    }

    // MARK: - Save Failures

    func testSaveFailureKeepsPublishedLogAndExposesSavingError()
        async {

        let repository = MockWorkoutLogRepository(
            saveResult: .failure(
                MockWorkoutLogRepository
                    .MockError
                    .saveFailed
            )
        )

        let saveExpectation = expectation(
            description: "Failed save attempted"
        )

        repository.setOnSave {
            saveExpectation.fulfill()
        }

        let store = WorkoutLogStore(
            repository: repository
        )

        store.add(
            WorkoutLogTestFactory.make(
                name: "Unsaved Workout",
                daysAgo: 0
            )
        )

        await fulfillment(
            of: [saveExpectation],
            timeout: 1
        )

        await waitForMainActorUpdates()

        XCTAssertEqual(
            store.logs.map(\.workoutName),
            ["Unsaved Workout"]
        )

        XCTAssertEqual(
            store.persistenceError?.operation,
            .saving
        )
    }

    func testSuccessfulSaveClearsPreviousSavingError()
        async {

        let repository = MockWorkoutLogRepository(
            saveResult: .failure(
                MockWorkoutLogRepository
                    .MockError
                    .saveFailed
            )
        )

        let firstSaveExpectation = expectation(
            description: "First save fails"
        )

        repository.setOnSave {
            firstSaveExpectation.fulfill()
        }

        let store = WorkoutLogStore(
            repository: repository
        )

        store.add(
            WorkoutLogTestFactory.make(
                name: "First",
                daysAgo: 1
            )
        )

        await fulfillment(
            of: [firstSaveExpectation],
            timeout: 1
        )

        await waitForMainActorUpdates()

        XCTAssertEqual(
            store.persistenceError?.operation,
            .saving
        )

        repository.setSaveResult(
            .success(())
        )

        let secondSaveExpectation = expectation(
            description: "Second save succeeds"
        )

        repository.setOnSave {
            secondSaveExpectation.fulfill()
        }

        store.add(
            WorkoutLogTestFactory.make(
                name: "Second",
                daysAgo: 0
            )
        )

        await fulfillment(
            of: [secondSaveExpectation],
            timeout: 1
        )

        await waitForMainActorUpdates()

        XCTAssertNil(
            store.persistenceError
        )
    }

    // MARK: - Read Protection

    func testLoadFailurePreventsSubsequentSaveAttempt()
        async {

        let repository = MockWorkoutLogRepository(
            loadResult: .failure(
                MockWorkoutLogRepository
                    .MockError
                    .loadFailed
            )
        )

        let store = WorkoutLogStore(
            repository: repository
        )

        store.add(
            WorkoutLogTestFactory.make(
                name: "Protected Workout",
                daysAgo: 0
            )
        )

        await waitForMainActorUpdates()

        XCTAssertEqual(
            repository.saveCallCount,
            0
        )

        XCTAssertEqual(
            store.logs.map(\.workoutName),
            ["Protected Workout"]
        )

        XCTAssertEqual(
            store.persistenceError?.operation,
            .saving
        )
    }

    // MARK: - Error Clearing

    func testClearPersistenceErrorRemovesCurrentError() {
        let repository = MockWorkoutLogRepository(
            loadResult: .failure(
                MockWorkoutLogRepository
                    .MockError
                    .loadFailed
            )
        )

        let store = WorkoutLogStore(
            repository: repository
        )

        XCTAssertNotNil(
            store.persistenceError
        )

        store.clearPersistenceError()

        XCTAssertNil(
            store.persistenceError
        )
    }

    // MARK: - Save Queue Ordering

    func testConsecutiveAddsPersistSnapshotsInSubmissionOrder()
        async {

        let repository = MockWorkoutLogRepository()

        let saveExpectation = expectation(
            description: "Both snapshots saved"
        )

        saveExpectation.expectedFulfillmentCount = 2

        repository.setOnSave {
            saveExpectation.fulfill()
        }

        let store = WorkoutLogStore(
            repository: repository
        )

        store.add(
            WorkoutLogTestFactory.make(
                name: "First",
                daysAgo: 1
            )
        )

        store.add(
            WorkoutLogTestFactory.make(
                name: "Second",
                daysAgo: 0
            )
        )

        await fulfillment(
            of: [saveExpectation],
            timeout: 1
        )

        let snapshots = repository.savedSnapshots

        XCTAssertEqual(
            snapshots.count,
            2
        )

        XCTAssertEqual(
            snapshots[0].map(\.workoutName),
            ["First"]
        )

        XCTAssertEqual(
            snapshots[1].map(\.workoutName),
            [
                "Second",
                "First"
            ]
        )
    }

    // MARK: - Helpers

    private func waitForMainActorUpdates()
        async {

        await Task.yield()
        await Task.yield()
    }
}
