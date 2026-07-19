import Foundation
@testable import MyWorkout

final class MockWorkoutTemplateRepository:
    WorkoutTemplateRepository,
    @unchecked Sendable {

    enum MockError: Error {
        case loadFailed
        case saveFailed
    }

    private struct State {
        var loadResult: Result<[WorkoutTemplate], Error>
        var saveResult: Result<Void, Error>
        var savedSnapshots: [[WorkoutTemplate]] = []
        var onSave: (() -> Void)?
    }

    private let state: ThreadSafeBox<State>

    init(
        loadResult: Result<[WorkoutTemplate], Error> = .success([]),
        saveResult: Result<Void, Error> = .success(())
    ) {
        state = ThreadSafeBox(
            State(
                loadResult: loadResult,
                saveResult: saveResult
            )
        )
    }

    var savedSnapshots: [[WorkoutTemplate]] {
        state.read { $0.savedSnapshots }
    }

    var lastSavedSnapshot: [WorkoutTemplate]? {
        state.read { $0.savedSnapshots.last }
    }

    var saveCallCount: Int {
        state.read { $0.savedSnapshots.count }
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

    func load() throws -> [WorkoutTemplate] {
        try state.read {
            try $0.loadResult.get()
        }
    }

    func save(
        _ templates: [WorkoutTemplate]
    ) throws {
        let captured:
            (
                result: Result<Void, Error>,
                onSave: (() -> Void)?
            ) = state.mutate {
                $0.savedSnapshots.append(templates)

                return (
                    $0.saveResult,
                    $0.onSave
                )
            }

        captured.onSave?()
        try captured.result.get()
    }
}
