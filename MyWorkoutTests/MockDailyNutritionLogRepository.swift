import Foundation
@testable import MyWorkout

final class MockDailyNutritionLogRepository:
    DailyNutritionLogRepository,
    @unchecked Sendable {

    enum MockError: Error {
        case loadFailed
        case saveFailed
    }

    private struct State {
        var loadResult: Result<[DailyNutritionLog], Error>
        var saveResult: Result<Void, Error>
        var savedSnapshots: [[DailyNutritionLog]] = []
    }

    private let state: ThreadSafeBox<State>

    init(
        loadResult: Result<[DailyNutritionLog], Error> = .success([]),
        saveResult: Result<Void, Error> = .success(())
    ) {
        state = ThreadSafeBox(
            State(
                loadResult: loadResult,
                saveResult: saveResult
            )
        )
    }

    var savedSnapshots: [[DailyNutritionLog]] {
        state.read { $0.savedSnapshots }
    }

    var lastSavedSnapshot: [DailyNutritionLog]? {
        state.read { $0.savedSnapshots.last }
    }

    var saveCallCount: Int {
        state.read { $0.savedSnapshots.count }
    }

    func setSaveResult(_ result: Result<Void, Error>) {
        state.mutate { $0.saveResult = result }
    }

    func load() throws -> [DailyNutritionLog] {
        try state.read { try $0.loadResult.get() }
    }

    func save(_ logs: [DailyNutritionLog]) throws {
        let result: Result<Void, Error> = state.mutate {
            $0.savedSnapshots.append(logs)
            return $0.saveResult
        }

        try result.get()
    }
}
