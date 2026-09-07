import XCTest
@testable import MyWorkout

@MainActor
final class BodyMeasurementLogStoreTests: XCTestCase {

    // MARK: - Loading

    func testInitializationLoadsPersistedLogsNewestFirst() {
        let older = BodyMeasurementLog(
            date: Date(timeIntervalSinceNow: -86_400),
            neckCm: 37
        )
        let newer = BodyMeasurementLog(date: .now, neckCm: 38)

        let repository = MockBodyMeasurementLogRepository(
            loadResult: .success([older, newer])
        )

        let store = BodyMeasurementLogStore(repository: repository)

        XCTAssertEqual(store.logs.map(\.id), [newer.id, older.id])
        XCTAssertNil(store.persistenceError)
    }

    func testInitializationWithNoPersistedDataStartsEmpty() {
        let repository = MockBodyMeasurementLogRepository()
        let store = BodyMeasurementLogStore(repository: repository)

        XCTAssertTrue(store.logs.isEmpty)
        XCTAssertNil(store.persistenceError)
    }

    func testLoadFailureExposesLoadingErrorAndPreservesNoData() {
        let repository = MockBodyMeasurementLogRepository(
            loadResult: .failure(MockBodyMeasurementLogRepository.MockError.loadFailed)
        )

        let store = BodyMeasurementLogStore(repository: repository)

        XCTAssertTrue(store.logs.isEmpty)
        XCTAssertEqual(store.persistenceError?.operation, .loading)
    }

    // MARK: - Add

    func testAddInsertsAtFrontAndPersists() {
        let repository = MockBodyMeasurementLogRepository()
        let store = BodyMeasurementLogStore(repository: repository)

        let log = BodyMeasurementLog(date: .now, neckCm: 38)
        store.add(log)

        XCTAssertEqual(store.logs.map(\.id), [log.id])
        XCTAssertEqual(repository.saveCallCount, 1)
        XCTAssertEqual(repository.lastSavedSnapshot?.map(\.id), [log.id])
    }

    // MARK: - Replace All (backup restore)

    func testReplaceAllNormalizesOutOfOrderInputToNewestFirst() {
        let older = BodyMeasurementLog(
            date: Date(timeIntervalSinceNow: -86_400),
            neckCm: 37
        )
        let newer = BodyMeasurementLog(date: .now, neckCm: 38)

        let repository = MockBodyMeasurementLogRepository()
        let store = BodyMeasurementLogStore(repository: repository)

        // Deliberately oldest-first input, as a chronological backup
        // export might hand back.
        store.replaceAll(with: [older, newer])

        XCTAssertEqual(store.logs.map(\.id), [newer.id, older.id])
    }

    // MARK: - Persistence Failure Guard

    /// Regression-style coverage for the exact class of bug that
    /// corrupted real production data earlier in this project: a store
    /// must never let a save silently overwrite data it couldn't itself
    /// read on load. This test only exercises the mock repository, never
    /// the real file-backed one.
    func testSaveIsBlockedAfterLoadFailure() {
        let repository = MockBodyMeasurementLogRepository(
            loadResult: .failure(MockBodyMeasurementLogRepository.MockError.loadFailed)
        )

        let store = BodyMeasurementLogStore(repository: repository)
        store.add(BodyMeasurementLog(date: .now, neckCm: 38))

        XCTAssertEqual(repository.saveCallCount, 0)
        XCTAssertEqual(store.persistenceError?.operation, .saving)
    }
}
