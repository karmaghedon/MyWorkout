import Foundation

/// Mirrors `WorkoutLogStore`'s shape exactly (same persistence-error
/// surfacing, same `isPersistenceWritable` guard against overwriting an
/// unreadable file, same background save queue).
@MainActor
final class BodyMeasurementLogStore: ObservableObject {
    @Published var logs: [BodyMeasurementLog] = []

    @Published private(set) var persistenceError: StoreError?

    private let repository: any BodyMeasurementLogRepository

    private let saveQueue = DispatchQueue(
        label: "com.myworkout.bodymeasurementlogstore.save",
        qos: .utility
    )

    /// Prevents unreadable persisted history from being overwritten.
    private var isPersistenceWritable = true

    init(
        repository: any BodyMeasurementLogRepository =
            FileBodyMeasurementLogRepository()
    ) {
        self.repository = repository
        load()
    }

    // MARK: - Log Actions

    func add(_ log: BodyMeasurementLog) {
        logs.insert(log, at: 0)
        save()
    }

    func replaceAll(with newLogs: [BodyMeasurementLog]) {
        logs = newLogs.sorted { $0.date > $1.date }
        save()
    }

    /// Replaces an existing entry in place, matched by `id` — used to
    /// correct a past neck/hip measurement (e.g. a typo) rather than
    /// leaving both the wrong and the corrected entry logged.
    func update(_ log: BodyMeasurementLog) {
        guard let index = logs.firstIndex(where: { $0.id == log.id }) else { return }

        logs[index] = log
        save()
    }

    func remove(id: UUID) {
        logs.removeAll { $0.id == id }
        save()
    }

    // MARK: - Persistence Errors

    func clearPersistenceError() {
        persistenceError = nil
    }

    private func setPersistenceError(
        operation: StoreOperation,
        message: String
    ) {
        persistenceError = StoreError(
            operation: operation,
            message: message
        )
    }

    private func clearPersistenceError(for operation: StoreOperation) {
        guard persistenceError?.operation == operation else {
            return
        }

        persistenceError = nil
    }

    // MARK: - Persistence

    private func load() {
        do {
            logs = try repository.load().sorted { $0.date > $1.date }
            isPersistenceWritable = true

            clearPersistenceError(for: .loading)
        } catch {
            isPersistenceWritable = false

            print("Failed to load body measurement logs: \(error)")

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't load your body measurement history. "
                    + "The existing data was preserved and will not "
                    + "be overwritten."
            )
        }
    }

    private func save() {
        guard isPersistenceWritable else {
            setPersistenceError(
                operation: .saving,
                message:
                    "Your body measurement history could not be read, "
                    + "so it was not overwritten. Restart the app or "
                    + "restore a valid backup before saving more "
                    + "measurements."
            )

            return
        }

        let logsToSave = logs
        let repository = repository

        saveQueue.async { [weak self] in
            do {
                try repository.save(logsToSave)

                DispatchQueue.main.async {
                    self?.clearPersistenceError(for: .saving)
                }
            } catch {
                print("Failed to save body measurement logs: \(error)")

                DispatchQueue.main.async {
                    self?.setPersistenceError(
                        operation: .saving,
                        message: "Couldn't save your measurement."
                    )
                }
            }
        }
    }
}
