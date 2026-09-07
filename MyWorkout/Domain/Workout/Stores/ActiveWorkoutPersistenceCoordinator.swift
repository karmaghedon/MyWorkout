import Foundation

final class ActiveWorkoutPersistenceCoordinator {
    enum Request {
        case save(ActiveWorkoutSnapshot)
        case delete
    }

    typealias FailureHandler = (
        StoreOperation,
        String
    ) -> Void

    private let persistence: any ActiveWorkoutPersisting
    private let saveQueue: DispatchQueue
    private var scheduledWorkItem: DispatchWorkItem?

    init(
        persistence: any ActiveWorkoutPersisting,
        saveQueue: DispatchQueue = DispatchQueue(
            label: "com.myworkout.activeworkoutstore.save",
            qos: .utility
        )
    ) {
        self.persistence = persistence
        self.saveQueue = saveQueue
    }

    func load() throws -> ActiveWorkoutSnapshot? {
        try persistence.load()
    }

    func deleteInvalidSnapshot() throws {
        try persistence.delete()
    }

    func cancelScheduledRequest() {
        scheduledWorkItem?.cancel()
        scheduledWorkItem = nil
    }

    func schedule(
        _ request: Request,
        delay: TimeInterval = 0.3,
        onSuccess: @escaping (StoreOperation) -> Void,
        onFailure: @escaping FailureHandler
    ) {
        cancelScheduledRequest()

        let workItem = DispatchWorkItem { [weak self] in
            self?.perform(
                request,
                onSuccess: onSuccess,
                onFailure: onFailure
            )
        }

        scheduledWorkItem = workItem

        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay,
            execute: workItem
        )
    }

    /// Forces a pending debounced write through immediately, and blocks
    /// until it (or any other write already in flight on this
    /// coordinator's queue) has actually finished. `schedule`'s 0.3s
    /// delay and `perform`'s background dispatch are both otherwise
    /// unguaranteed to complete before the process suspends — call this
    /// when the app is about to background or terminate.
    func flush(
        _ request: Request,
        onSuccess: @escaping (StoreOperation) -> Void,
        onFailure: @escaping FailureHandler
    ) {
        if scheduledWorkItem != nil {
            cancelScheduledRequest()
            perform(request, onSuccess: onSuccess, onFailure: onFailure)
        }

        saveQueue.sync {}
    }

    func perform(
        _ request: Request,
        onSuccess: @escaping (StoreOperation) -> Void,
        onFailure: @escaping FailureHandler
    ) {
        let persistence = persistence

        saveQueue.async {
            do {
                let operation: StoreOperation

                switch request {
                case let .save(snapshot):
                    try persistence.save(snapshot)
                    operation = .saving

                case .delete:
                    try persistence.delete()
                    operation = .deleting
                }

                DispatchQueue.main.async {
                    onSuccess(operation)
                }
            } catch {
                let operation: StoreOperation
                let message: String

                switch request {
                case .save:
                    operation = .saving
                    message =
                        "Couldn't save your active workout. "
                        + "If the app closes, you may lose progress "
                        + "on this session."

                case .delete:
                    operation = .deleting
                    message =
                        "Couldn't clear the saved active workout."
                }

                print(
                    "Active workout persistence failed: "
                    + error.localizedDescription
                )

                DispatchQueue.main.async {
                    onFailure(
                        operation,
                        message
                    )
                }
            }
        }
    }
}
