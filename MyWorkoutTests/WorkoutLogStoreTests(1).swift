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
