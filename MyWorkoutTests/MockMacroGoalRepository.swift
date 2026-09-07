import Foundation
@testable import MyWorkout

final class MockMacroGoalRepository:
    MacroGoalRepository,
    @unchecked Sendable {

    enum MockError: Error {
        case loadFailed
        case saveFailed
    }

    private struct State {
        var loadResult: Result<[MacroGoal], Error>
        var saveResult: Result<Void, Error>
        var savedSnapshots: [[MacroGoal]] = []
    }

    private let state: ThreadSafeBox<State>

    init(
        loadResult: Result<[MacroGoal], Error> = .success([]),
        saveResult: Result<Void, Error> = .success(())
    ) {
        state = ThreadSafeBox(
            State(
                loadResult: loadResult,
                saveResult: saveResult
            )
        )
    }

    var savedSnapshots: [[MacroGoal]] {
        state.read { $0.savedSnapshots }
    }

    var lastSavedSnapshot: [MacroGoal]? {
        state.read { $0.savedSnapshots.last }
    }

    var saveCallCount: Int {
        state.read { $0.savedSnapshots.count }
    }

    func setSaveResult(_ result: Result<Void, Error>) {
        state.mutate { $0.saveResult = result }
    }

    func load() throws -> [MacroGoal] {
        try state.read { try $0.loadResult.get() }
    }

    func save(_ goals: [MacroGoal]) throws {
        let result: Result<Void, Error> = state.mutate {
            $0.savedSnapshots.append(goals)
            return $0.saveResult
        }

        try result.get()
    }
}
