import XCTest
@testable import MyWorkout

@MainActor
final class DailyNutritionLogStoreTests: XCTestCase {

    private func date(_ daysFromNow: Int) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: daysFromNow,
            to: .now
        )!
    }

    // MARK: - Loading

    func testInitializationLoadsPersistedLogsNewestFirst() {
        let older = DailyNutritionLog(date: date(-10), proteinG: 100, carbsG: 150, fatG: 50)
        let newer = DailyNutritionLog(date: date(-1), proteinG: 120, carbsG: 160, fatG: 55)

        let repository = MockDailyNutritionLogRepository(
            loadResult: .success([older, newer])
        )

        let store = DailyNutritionLogStore(repository: repository)

        XCTAssertEqual(store.logs.map(\.id), [newer.id, older.id])
        XCTAssertNil(store.persistenceError)
    }

    func testInitializationWithNoPersistedDataStartsEmpty() {
        let repository = MockDailyNutritionLogRepository()
        let store = DailyNutritionLogStore(repository: repository)

        XCTAssertTrue(store.logs.isEmpty)
        XCTAssertNil(store.persistenceError)
    }

    func testLoadFailureExposesLoadingErrorAndPreservesNoData() {
        let repository = MockDailyNutritionLogRepository(
            loadResult: .failure(MockDailyNutritionLogRepository.MockError.loadFailed)
        )

        let store = DailyNutritionLogStore(repository: repository)

        XCTAssertTrue(store.logs.isEmpty)
        XCTAssertEqual(store.persistenceError?.operation, .loading)
    }

    // MARK: - Upsert

    func testUpsertInsertsNewRecordForUnloggedDay() {
        let repository = MockDailyNutritionLogRepository()
        let store = DailyNutritionLogStore(repository: repository)

        store.upsert(date: date(0), proteinG: 150, carbsG: 200, fatG: 65)

        XCTAssertEqual(store.logs.count, 1)
        XCTAssertEqual(store.logs.first?.proteinG, 150)
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testUpsertReplacesExistingRecordForSameDayRatherThanAdding() {
        let repository = MockDailyNutritionLogRepository()
        let store = DailyNutritionLogStore(repository: repository)

        store.upsert(date: date(0), proteinG: 100, carbsG: 100, fatG: 40)
        store.upsert(date: date(0), proteinG: 160, carbsG: 210, fatG: 70)

        XCTAssertEqual(store.logs.count, 1)
        XCTAssertEqual(store.logs.first?.proteinG, 160)
        XCTAssertEqual(store.logs.first?.carbsG, 210)
        XCTAssertEqual(store.logs.first?.fatG, 70)
    }

    func testUpsertKeepsSeparateDaysAsSeparateRecords() {
        let repository = MockDailyNutritionLogRepository()
        let store = DailyNutritionLogStore(repository: repository)

        store.upsert(date: date(-1), proteinG: 100, carbsG: 100, fatG: 40)
        store.upsert(date: date(0), proteinG: 160, carbsG: 210, fatG: 70)

        XCTAssertEqual(store.logs.count, 2)
    }

    // MARK: - Calories

    func testCaloriesAreDerivedFromMacrosUsingFourFourNineRule() {
        let log = DailyNutritionLog(date: .now, proteinG: 150, carbsG: 200, fatG: 65)

        XCTAssertEqual(log.calories, 150 * 4 + 200 * 4 + 65 * 9)
    }

    // MARK: - entry(on:)

    func testEntryOnDateReturnsMatchingDayOnly() {
        let repository = MockDailyNutritionLogRepository()
        let store = DailyNutritionLogStore(repository: repository)

        store.upsert(date: date(0), proteinG: 150, carbsG: 200, fatG: 65)
        store.upsert(date: date(-1), proteinG: 100, carbsG: 100, fatG: 40)

        XCTAssertEqual(store.entry(on: date(0))?.proteinG, 150)
        XCTAssertNil(store.entry(on: date(-5)))
    }

    // MARK: - Delete

    func testDeleteRemovesRecordAndPersists() {
        let repository = MockDailyNutritionLogRepository()
        let store = DailyNutritionLogStore(repository: repository)

        store.upsert(date: date(0), proteinG: 150, carbsG: 200, fatG: 65)
        let id = store.logs[0].id

        store.delete(id: id)

        XCTAssertTrue(store.logs.isEmpty)
    }

    // MARK: - Replace All (backup restore)

    func testReplaceAllNormalizesOutOfOrderInputToNewestFirst() {
        let older = DailyNutritionLog(date: date(-10), proteinG: 100, carbsG: 150, fatG: 50)
        let newer = DailyNutritionLog(date: date(-1), proteinG: 120, carbsG: 160, fatG: 55)

        let repository = MockDailyNutritionLogRepository()
        let store = DailyNutritionLogStore(repository: repository)

        store.replaceAll(with: [older, newer])

        XCTAssertEqual(store.logs.map(\.id), [newer.id, older.id])
    }

    // MARK: - Persistence Failure Guard

    func testSaveIsBlockedAfterLoadFailure() {
        let repository = MockDailyNutritionLogRepository(
            loadResult: .failure(MockDailyNutritionLogRepository.MockError.loadFailed)
        )

        let store = DailyNutritionLogStore(repository: repository)
        store.upsert(date: date(0), proteinG: 150, carbsG: 200, fatG: 65)

        XCTAssertEqual(repository.saveCallCount, 0)
        XCTAssertEqual(store.persistenceError?.operation, .saving)
    }
}
