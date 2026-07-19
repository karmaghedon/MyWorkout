import Foundation
@testable import MyWorkout

final class MockWorkoutLogRepository:
    WorkoutLogRepository,
    @unchecked Sendable {

    enum MockError: Error {
        case loadFailed
        case saveFailed
    }

    private struct State {
        var loadResult:
            Result<[WorkoutLog], Error>

        var saveResult:
            Result<Void, Error>

        var savedSnapshots:
            [[WorkoutLog]] = []

        var onSave:
            (() -> Void)?
    }

    private let state: ThreadSafeBox<State>

    init(
        loadResult: Result<[WorkoutLog], Error> =
            .success([]),
        saveResult: Result<Void, Error> =
            .success(())
    ) {
        state = ThreadSafeBox(
            State(
                loadResult: loadResult,
                saveResult: saveResult
            )
        )
    }

    var savedSnapshots: [[WorkoutLog]] {
        state.read {
            $0.savedSnapshots
        }
    }

    var lastSavedSnapshot: [WorkoutLog]? {
        state.read {
            $0.savedSnapshots.last
        }
    }

    var saveCallCount: Int {
        state.read {
            $0.savedSnapshots.count
        }
    }

    func setLoadResult(
        _ result: Result<[WorkoutLog], Error>
    ) {
        state.mutate {
            $0.loadResult = result
        }
    }

    func setSaveResult(
        _ result: Result<Void, Error>
    ) {
        state.mutate {
            $0.saveResult = result
        }
    }

    func setOnSave(
        _ action: (() -> Void)?
    ) {
        state.mutate {
            $0.onSave = action
        }
    }

    func load() throws -> [WorkoutLog] {
        let result = state.read {
            $0.loadResult
        }

        return try result.get()
    }

    func save(
        _ logs: [WorkoutLog]
    ) throws {
        let captured:
            (
                result: Result<Void, Error>,
                onSave: (() -> Void)?
            ) = state.mutate {
                $0.savedSnapshots.append(logs)

                return (
                    $0.saveResult,
                    $0.onSave
                )
            }

        captured.onSave?()

        try captured.result.get()
    }
}
