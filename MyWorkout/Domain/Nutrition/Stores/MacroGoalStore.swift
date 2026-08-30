import Foundation

/// Mirrors `BodyMeasurementLogStore`'s shape exactly (same persistence-error
/// surfacing, same `isPersistenceWritable` guard against overwriting an
/// unreadable file, same background save queue).
@MainActor
final class MacroGoalStore: ObservableObject {
    @Published var goals: [MacroGoal] = []

    @Published private(set) var persistenceError: StoreError?

    private let repository: any MacroGoalRepository

    private let saveQueue = DispatchQueue(
        label: "com.myworkout.macrogoalstore.save",
        qos: .utility
    )

    /// Prevents unreadable persisted history from being overwritten.
    private var isPersistenceWritable = true

    init(
        repository: any MacroGoalRepository = FileMacroGoalRepository()
    ) {
        self.repository = repository
        load()
    }

    // MARK: - Goal Actions

    func add(_ goal: MacroGoal) {
        goals.append(goal)
        goals.sort { $0.effectiveDate > $1.effectiveDate }
        save()
    }

    func delete(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
        save()
    }

    func replaceAll(with newGoals: [MacroGoal]) {
        goals = newGoals.sorted { $0.effectiveDate > $1.effectiveDate }
        save()
    }

    /// The goal that applies on `date`: the one with the latest
    /// `effectiveDate` that is still `<= date`. If no goal has started yet
    /// as of `date` (every goal is future-dated), falls back to the goal
    /// with the latest `effectiveDate` overall, so a future-dated goal
    /// never leaves "today" with nothing to show.
    func activeGoal(on date: Date) -> MacroGoal? {
        let eligible = goals.filter { $0.effectiveDate <= date }

        if let mostRecentEligible = eligible.max(by: { $0.effectiveDate < $1.effectiveDate }) {
            return mostRecentEligible
        }

        return goals.max(by: { $0.effectiveDate < $1.effectiveDate })
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
            goals = try repository.load().sorted { $0.effectiveDate > $1.effectiveDate }
            isPersistenceWritable = true

            clearPersistenceError(for: .loading)
        } catch {
            isPersistenceWritable = false

            print("Failed to load macro goals: \(error)")

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't load your macro goal history. "
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
                    "Your macro goal history could not be read, "
                    + "so it was not overwritten. Restart the app or "
                    + "restore a valid backup before saving more "
                    + "goals."
            )

            return
        }

        let goalsToSave = goals
        let repository = repository

        saveQueue.async { [weak self] in
            do {
                try repository.save(goalsToSave)

                DispatchQueue.main.async {
                    self?.clearPersistenceError(for: .saving)
                }
            } catch {
                print("Failed to save macro goals: \(error)")

                DispatchQueue.main.async {
                    self?.setPersistenceError(
                        operation: .saving,
                        message: "Couldn't save your macro goal."
                    )
                }
            }
        }
    }
}
