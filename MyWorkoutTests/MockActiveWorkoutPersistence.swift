import Foundation
@testable import MyWorkout

final class MockActiveWorkoutPersistence:
    ActiveWorkoutPersisting,
    @unchecked Sendable {

    enum MockError: Error {
        case loadFailed
        case saveFailed
        case deleteFailed
    }

    private struct State {
        var loadResult:
            Result<ActiveWorkoutSnapshot?, Error>

        var saveResult:
            Result<Void, Error>

        var deleteResult:
            Result<Void, Error>

        var savedSnapshots:
            [ActiveWorkoutSnapshot] = []

        var deleteCallCount = 0

        var onSave:
            (() -> Void)?

        var onDelete:
            (() -> Void)?
    }

    private let state: ThreadSafeBox<State>

    init(
        loadResult:
            Result<ActiveWorkoutSnapshot?, Error> =
                .success(nil),
        saveResult:
            Result<Void, Error> =
                .success(()),
        deleteResult:
            Result<Void, Error> =
                .success(())
    ) {
        state = ThreadSafeBox(
            State(
                loadResult: loadResult,
                saveResult: saveResult,
                deleteResult: deleteResult
            )
        )
    }

    var savedSnapshots: [ActiveWorkoutSnapshot] {
        state.read {
            $0.savedSnapshots
        }
    }

    var lastSavedSnapshot: ActiveWorkoutSnapshot? {
        state.read {
            $0.savedSnapshots.last
        }
    }

    var saveCallCount: Int {
        state.read {
            $0.savedSnapshots.count
        }
    }

    var deleteCallCount: Int {
        state.read {
            $0.deleteCallCount
        }
    }

    func setSaveResult(
        _ result: Result<Void, Error>
    ) {
        state.mutate {
            $0.saveResult = result
        }
    }

    func setDeleteResult(
        _ result: Result<Void, Error>
    ) {
        state.mutate {
            $0.deleteResult = result
        }
    }

    func setOnSave(
        _ action: (() -> Void)?
    ) {
        state.mutate {
            $0.onSave = action
        }
    }

    func setOnDelete(
        _ action: (() -> Void)?
    ) {
        state.mutate {
            $0.onDelete = action
        }
    }

    func save(
        _ snapshot: ActiveWorkoutSnapshot
    ) throws {
        let captured:
            (
                result: Result<Void, Error>,
                onSave: (() -> Void)?
            ) = state.mutate {
                $0.savedSnapshots.append(snapshot)

                let onSave = $0.onSave
                $0.onSave = nil

                return (
                    $0.saveResult,
                    onSave
                )
            }

        captured.onSave?()

        try captured.result.get()
    }

    func load() throws -> ActiveWorkoutSnapshot? {
        try state.read {
            try $0.loadResult.get()
        }
    }

    func delete() throws {
        let captured:
            (
                result: Result<Void, Error>,
                onDelete: (() -> Void)?
            ) = state.mutate {
                $0.deleteCallCount += 1

                let onDelete = $0.onDelete
                $0.onDelete = nil

                return (
                    $0.deleteResult,
                    onDelete
                )
            }

        captured.onDelete?()

        try captured.result.get()
    }
}

