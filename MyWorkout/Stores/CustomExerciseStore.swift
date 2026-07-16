import Foundation

@MainActor
final class CustomExerciseStore: ObservableObject {
    @Published private(set)
    var storedExercises: [StoredCustomExercise] = []

    @Published private(set)
    var persistenceError: StoreError?

    private let repository: any CustomExerciseRepository

    /// Prevents unreadable persisted data from being overwritten.
    private var isPersistenceWritable = true

    init(
        repository: any CustomExerciseRepository =
            FileCustomExerciseRepository()
    ) {
        self.repository = repository
        load()
    }

    // MARK: - Derived Collections

    var activeExercises: [Exercise] {
        storedExercises
            .filter { !$0.isArchived }
            .map(\.exercise)
            .sorted {
                $0.name.localizedCaseInsensitiveCompare(
                    $1.name
                ) == .orderedAscending
            }
    }

    var archivedExercises: [Exercise] {
        storedExercises
            .filter(\.isArchived)
            .map(\.exercise)
            .sorted {
                $0.name.localizedCaseInsensitiveCompare(
                    $1.name
                ) == .orderedAscending
            }
    }

    var allExercises: [Exercise] {
        storedExercises.map(\.exercise)
    }

    // MARK: - Queries

    func exercise(
        id: UUID
    ) -> Exercise? {
        storedExercises.first {
            $0.id == id
        }?.exercise
    }

    func storedExercise(
        id: UUID
    ) -> StoredCustomExercise? {
        storedExercises.first {
            $0.id == id
        }
    }

    func containsExercise(
        id: UUID
    ) -> Bool {
        storedExercises.contains {
            $0.id == id
        }
    }

    func containsActiveExercise(
        named name: String,
        excluding exerciseID: UUID? = nil
    ) -> Bool {
        let normalizedName = normalized(name)

        return storedExercises.contains { storedExercise in
            guard !storedExercise.isArchived,
                  storedExercise.id != exerciseID else {
                return false
            }

            return normalized(
                storedExercise.exercise.name
            ) == normalizedName
        }
    }

    // MARK: - Create

    @discardableResult
    func create(
        _ exercise: Exercise
    ) -> Bool {
        guard isPersistenceWritable else {
            reportBlockedSave()
            return false
        }

        guard !containsExercise(id: exercise.id) else {
            setPersistenceError(
                operation: .saving,
                message:
                    "A custom exercise with this identifier "
                    + "already exists."
            )

            return false
        }

        guard !containsActiveExercise(
            named: exercise.name
        ) else {
            setPersistenceError(
                operation: .saving,
                message:
                    "An active custom exercise with this name "
                    + "already exists."
            )

            return false
        }

        let now = Date()

        storedExercises.append(
            StoredCustomExercise(
                exercise: exercise,
                isArchived: false,
                createdAt: now,
                updatedAt: now
            )
        )

        sortStoredExercises()
        save()

        return true
    }

    // MARK: - Update

    @discardableResult
    func update(
        _ exercise: Exercise
    ) -> Bool {
        guard isPersistenceWritable else {
            reportBlockedSave()
            return false
        }

        guard let index = storedExercises.firstIndex(
            where: { $0.id == exercise.id }
        ) else {
            setPersistenceError(
                operation: .saving,
                message:
                    "The custom exercise could not be found."
            )

            return false
        }

        guard !containsActiveExercise(
            named: exercise.name,
            excluding: exercise.id
        ) else {
            setPersistenceError(
                operation: .saving,
                message:
                    "Another active custom exercise already "
                    + "uses this name."
            )

            return false
        }

        let existing = storedExercises[index]

        storedExercises[index] = StoredCustomExercise(
            exercise: exercise,
            isArchived: existing.isArchived,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )

        sortStoredExercises()
        save()

        return true
    }

    // MARK: - Archive

    @discardableResult
    func archive(
        exerciseID: UUID
    ) -> Bool {
        guard isPersistenceWritable else {
            reportBlockedSave()
            return false
        }

        guard let index = storedExercises.firstIndex(
            where: { $0.id == exerciseID }
        ) else {
            return false
        }

        guard !storedExercises[index].isArchived else {
            return true
        }

        let existing = storedExercises[index]

        storedExercises[index] = StoredCustomExercise(
            exercise: existing.exercise,
            isArchived: true,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )

        sortStoredExercises()
        save()

        return true
    }

    // MARK: - Restore

    @discardableResult
    func restore(
        exerciseID: UUID
    ) -> Bool {
        guard isPersistenceWritable else {
            reportBlockedSave()
            return false
        }

        guard let index = storedExercises.firstIndex(
            where: { $0.id == exerciseID }
        ) else {
            return false
        }

        let existing = storedExercises[index]

        guard existing.isArchived else {
            return true
        }

        guard !containsActiveExercise(
            named: existing.exercise.name,
            excluding: exerciseID
        ) else {
            setPersistenceError(
                operation: .saving,
                message:
                    "This exercise cannot be restored because "
                    + "another active exercise uses the same name."
            )

            return false
        }

        storedExercises[index] = StoredCustomExercise(
            exercise: existing.exercise,
            isArchived: false,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )

        sortStoredExercises()
        save()

        return true
    }

    // MARK: - Backup Replacement

    func replaceAll(
        with exercises: [StoredCustomExercise]
    ) {
        guard isPersistenceWritable else {
            reportBlockedSave()
            return
        }

        storedExercises = exercises
        sortStoredExercises()
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

    private func clearPersistenceError(
        for operation: StoreOperation
    ) {
        guard persistenceError?.operation == operation else {
            return
        }

        persistenceError = nil
    }

    private func reportBlockedSave() {
        setPersistenceError(
            operation: .saving,
            message:
                "Custom exercises could not be saved because "
                + "the existing saved data could not be read."
        )
    }

    // MARK: - Persistence

    private func load() {
        do {
            storedExercises = try repository.load()
            sortStoredExercises()

            isPersistenceWritable = true
            clearPersistenceError(for: .loading)
        } catch {
            isPersistenceWritable = false

            print(
                "Failed to load custom exercises: \(error)"
            )

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't load your custom exercises. "
                    + "The existing data was preserved and "
                    + "will not be overwritten."
            )
        }
    }

    private func save() {
        guard isPersistenceWritable else {
            reportBlockedSave()
            return
        }

        do {
            try repository.save(
                storedExercises
            )

            clearPersistenceError(for: .saving)
        } catch {
            print(
                "Failed to save custom exercises: \(error)"
            )

            setPersistenceError(
                operation: .saving,
                message:
                    "Couldn't save custom exercises."
            )
        }
    }

    // MARK: - Helpers

    private func sortStoredExercises() {
        storedExercises.sort {
            $0.exercise.name
                .localizedCaseInsensitiveCompare(
                    $1.exercise.name
                ) == .orderedAscending
        }
    }

    private func normalized(
        _ value: String
    ) -> String {
        value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .folding(
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive
                ],
                locale: .current
            )
    }
}
