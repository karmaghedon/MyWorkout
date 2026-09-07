import XCTest
@testable import MyWorkout

@MainActor
final class MacroGoalStoreTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ daysFromNow: Int) -> Date {
        calendar.date(
            byAdding: .day,
            value: daysFromNow,
            to: Date(timeIntervalSince1970: 1_700_000_000)
        )!
    }

    private func goal(_ daysFromNow: Int, calories: Int = 2_000) -> MacroGoal {
        MacroGoal(
            effectiveDate: date(daysFromNow),
            calories: calories,
            proteinG: 150,
            carbsG: 200,
            fatG: 65
        )
    }

    // MARK: - Loading

    func testInitializationLoadsPersistedGoalsNewestFirst() {
        let older = goal(-10)
        let newer = goal(-1)

        let repository = MockMacroGoalRepository(
            loadResult: .success([older, newer])
        )

        let store = MacroGoalStore(repository: repository)

        XCTAssertEqual(store.goals.map(\.id), [newer.id, older.id])
        XCTAssertNil(store.persistenceError)
    }

    func testInitializationWithNoPersistedDataStartsEmpty() {
        let repository = MockMacroGoalRepository()
        let store = MacroGoalStore(repository: repository)

        XCTAssertTrue(store.goals.isEmpty)
        XCTAssertNil(store.persistenceError)
    }

    func testLoadFailureExposesLoadingErrorAndPreservesNoData() {
        let repository = MockMacroGoalRepository(
            loadResult: .failure(MockMacroGoalRepository.MockError.loadFailed)
        )

        let store = MacroGoalStore(repository: repository)

        XCTAssertTrue(store.goals.isEmpty)
        XCTAssertEqual(store.persistenceError?.operation, .loading)
    }

    // MARK: - Add / Delete

    func testAddInsertsAndKeepsNewestFirst() {
        let repository = MockMacroGoalRepository()
        let store = MacroGoalStore(repository: repository)

        let older = goal(-10)
        let newer = goal(-1)

        store.add(older)
        store.add(newer)

        XCTAssertEqual(store.goals.map(\.id), [newer.id, older.id])
        XCTAssertEqual(repository.saveCallCount, 2)
    }

    func testDeleteRemovesAtOffsetAndPersists() {
        let repository = MockMacroGoalRepository()
        let store = MacroGoalStore(repository: repository)

        let a = goal(-10)
        let b = goal(-1)
        store.add(a)
        store.add(b)

        store.delete(at: IndexSet(integer: 0))

        XCTAssertEqual(store.goals.map(\.id), [a.id])
        XCTAssertEqual(repository.lastSavedSnapshot?.map(\.id), [a.id])
    }

    // MARK: - Replace All (backup restore)

    func testReplaceAllNormalizesOutOfOrderInputToNewestFirst() {
        let older = goal(-10)
        let newer = goal(-1)

        let repository = MockMacroGoalRepository()
        let store = MacroGoalStore(repository: repository)

        store.replaceAll(with: [older, newer])

        XCTAssertEqual(store.goals.map(\.id), [newer.id, older.id])
    }

    // MARK: - activeGoal(on:) boundary cases

    func testActiveGoalWithNoGoalsReturnsNil() {
        let store = MacroGoalStore(repository: MockMacroGoalRepository())

        XCTAssertNil(store.activeGoal(on: date(0)))
    }

    func testActiveGoalReturnsExactMatchOnEffectiveDate() {
        let store = MacroGoalStore(repository: MockMacroGoalRepository())
        let onDate = goal(0, calories: 2_100)

        store.add(goal(-10, calories: 1_900))
        store.add(onDate)

        let active = store.activeGoal(on: date(0))

        XCTAssertEqual(active?.id, onDate.id)
    }

    func testActiveGoalFillsGapWithMostRecentPriorGoal() {
        let store = MacroGoalStore(repository: MockMacroGoalRepository())
        let early = goal(-30, calories: 1_800)
        let mid = goal(-10, calories: 2_000)

        store.add(early)
        store.add(mid)

        // No goal was set exactly "today" (day 0) — the most recent one
        // that had already started (day -10) should still apply.
        let active = store.activeGoal(on: date(0))

        XCTAssertEqual(active?.id, mid.id)
    }

    func testActiveGoalBeforeAnyGoalStartedFallsBackToMostRecentOverall() {
        let store = MacroGoalStore(repository: MockMacroGoalRepository())
        let soonest = goal(5, calories: 2_200)
        let farthest = goal(20, calories: 2_400)

        store.add(soonest)
        store.add(farthest)

        // Querying before either goal's effectiveDate: neither is
        // eligible, so the one with the latest effectiveDate overall wins
        // rather than leaving "today" with nothing.
        let active = store.activeGoal(on: date(0))

        XCTAssertEqual(active?.id, farthest.id)
    }
}
