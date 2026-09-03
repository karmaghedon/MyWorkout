import Foundation

/// Mirrors `MacroGoalStore`'s shape (same persistence-error surfacing,
/// same `isPersistenceWritable` guard, same background save queue), but
/// the mutation is `upsert` rather than `add`: at most one record exists
/// per calendar day, edited in place as the day's totals change rather
/// than accumulated from separate entries.
@MainActor
final class DailyNutritionLogStore: ObservableObject {
    @Published var logs: [DailyNutritionLog] = []

    @Published private(set) var persistenceError: StoreError?

    private let repository: any DailyNutritionLogRepository

    private let saveQueue = DispatchQueue(
        label: "com.myworkout.dailynutritionlogstore.save",
        qos: .utility
    )

    /// Prevents unreadable persisted history from being overwritten.
    private var isPersistenceWritable = true

    init(
        repository: any DailyNutritionLogRepository = FileDailyNutritionLogRepository()
    ) {
        self.repository = repository
        load()
    }

    // MARK: - Log Actions

    /// Replaces the existing record for `date`'s calendar day, if any,
    /// otherwise inserts a new one.
    func upsert(
        date: Date,
        proteinG: Int,
        carbsG: Int,
        fatG: Int
    ) {
        let calendar = Calendar.current
        let newLog = DailyNutritionLog(
            date: date,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG
        )

        if let index = logs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            logs[index] = newLog
        } else {
            logs.append(newLog)
            logs.sort { $0.date > $1.date }
        }

        save()
    }

    func delete(id: UUID) {
        logs.removeAll { $0.id == id }
        save()
    }

    func replaceAll(with newLogs: [DailyNutritionLog]) {
        logs = newLogs.sorted { $0.date > $1.date }
        save()
    }

    func entry(on date: Date) -> DailyNutritionLog? {
        let calendar = Calendar.current
        return logs.first { calendar.isDate($0.date, inSameDayAs: date) }
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

            print("Failed to load daily nutrition logs: \(error)")

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't load your nutrition history. "
                    + "The existing data was preserved and will not "
                    + "be overwritten."
            )
        }
    }

    /// Blocks until any save already queued by `save()` has actually
    /// finished writing to disk — call when the app is about to
    /// background or terminate, since `save()`'s dispatch to
    /// `saveQueue` is not otherwise guaranteed to complete before the
    /// process is suspended or killed.
    func flushPendingSave() {
        saveQueue.sync {}
    }

    private func save() {
        guard isPersistenceWritable else {
            setPersistenceError(
                operation: .saving,
                message:
                    "Your nutrition history could not be read, "
                    + "so it was not overwritten. Restart the app or "
                    + "restore a valid backup before saving more "
                    + "entries."
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
                print("Failed to save daily nutrition logs: \(error)")

                DispatchQueue.main.async {
                    self?.setPersistenceError(
                        operation: .saving,
                        message: "Couldn't save your nutrition entry."
                    )
                }
            }
        }
    }
}
