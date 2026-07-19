import Foundation

@MainActor
final class CustomExerciseStore: ObservableObject {
    @Published private(set)
    var storedExercises: [StoredCustomExercise] = []

    @Published private(set)
    var persistenceError: StoreError?

    private let repository: any CustomExerciseRepository
    private let reservedExercises: [Exercise]

    /// Prevents unreadable persisted data from being overwritten.
    private var isPersistenceWritable = true

    init(
        repository: any CustomExerciseRepository =
            FileCustomExerciseRepository(),
        reservedExercises: [Exercise] =
            SeedData.exercises
    ) {
        self.repository = repository
        self.reservedExercises = reservedExercises
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

    func containsExercise(
        named name: String,
        excluding exerciseID: UUID? = nil
    ) -> Bool {
        isDuplicateName(
            name,
            in: storedExercises,
            excluding: exerciseID
        )
    }

    // MARK: - Create

    @discardableResult
    func create(
        _ exercise: Exercise
    ) -> Bool {
        performMutation { candidate in
            guard !candidate.contains(
                where: { $0.id == exercise.id }
            ) else {
                setPersistenceError(
                    operation: .saving,
                    message:
                        "A custom exercise with this identifier "
                        + "already exists."
                )

                return .rejected
            }

            guard !isDuplicateName(
                exercise.name,
                in: candidate
            ) else {
                setPersistenceError(
                    operation: .saving,
                    message:
                        "A custom exercise with this name already "
                        + "exists, including archived exercises."
                )

                return .rejected
            }

            let now = Date()

            candidate.append(
                StoredCustomExercise(
                    exercise: exercise,
                    isArchived: false,
                    createdAt: now,
                    updatedAt: now
                )
            )

            return .persist
        }
    }

    // MARK: - Update

    @discardableResult
    func update(
        _ exercise: Exercise
    ) -> Bool {
        performMutation { candidate in
            guard let index = candidate.firstIndex(
                where: { $0.id == exercise.id }
            ) else {
                setPersistenceError(
                    operation: .saving,
                    message:
                        "The custom exercise could not be found."
                )

                return .rejected
            }

            guard !isDuplicateName(
                exercise.name,
                in: candidate,
                excluding: exercise.id
            ) else {
                setPersistenceError(
                    operation: .saving,
                    message:
                        "Another custom exercise already uses this "
                        + "name, including archived exercises."
                )

                return .rejected
            }

            let existing = candidate[index]

            candidate[index] = StoredCustomExercise(
                exercise: exercise,
                isArchived: existing.isArchived,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )

            return .persist
        }
    }

    // MARK: - Permanent Deletion

    @discardableResult
    func permanentlyDelete(
        exerciseID: UUID
    ) -> Bool {
        performMutation { candidate in
            guard let index = candidate.firstIndex(
                where: { $0.id == exerciseID }
            ) else {
                return .rejected
            }

            guard candidate[index].isArchived else {
                setPersistenceError(
                    operation: .saving,
                    message:
                        "Only archived custom exercises "
                        + "can be permanently deleted."
                )

                return .rejected
            }

            candidate.remove(at: index)

            return .persist
        }
    }

    // MARK: - Archive

    @discardableResult
    func archive(
        exerciseID: UUID
    ) -> Bool {
        performMutation { candidate in
            guard let index = candidate.firstIndex(
                where: { $0.id == exerciseID }
            ) else {
                return .rejected
            }

            guard !candidate[index].isArchived else {
                return .succeededWithoutPersistence
            }

            let existing = candidate[index]

            candidate[index] = StoredCustomExercise(
                exercise: existing.exercise,
                isArchived: true,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )

            return .persist
        }
    }

    // MARK: - Restore

    @discardableResult
    func restore(
        exerciseID: UUID
    ) -> Bool {
        performMutation { candidate in
            guard let index = candidate.firstIndex(
                where: { $0.id == exerciseID }
            ) else {
                return .rejected
            }

            let existing = candidate[index]

            guard existing.isArchived else {
                return .succeededWithoutPersistence
            }

            guard !isDuplicateName(
                existing.exercise.name,
                in: candidate,
                excluding: exerciseID
            ) else {
                setPersistenceError(
                    operation: .saving,
                    message:
                        "This exercise cannot be restored because "
                        + "another custom exercise uses the same name."
                )

                return .rejected
            }

            candidate[index] = StoredCustomExercise(
                exercise: existing.exercise,
                isArchived: false,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )

            return .persist
        }
    }

    // MARK: - Backup Replacement

    @discardableResult
    func replaceAll(
        with exercises: [StoredCustomExercise]
    ) -> Bool {
        guard canAttemptSave() else {
            return false
        }

        let validationResult =
            CustomExerciseImportValidator.validate(
                exercises,
                reservedExercises: reservedExercises
            )

        guard validationResult == .valid else {
            setPersistenceError(
                operation: .saving,
                message:
                    validationResult.message
                    ?? "The imported custom exercises are invalid."
            )

            return false
        }

        return persistAndPublish(
            exercises
        )
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

    // MARK: - Mutation Coordination

    private enum MutationOutcome {
        case persist
        case succeededWithoutPersistence
        case rejected
    }

    private func performMutation(
        _ mutation: (
            inout [StoredCustomExercise]
        ) -> MutationOutcome
    ) -> Bool {
        guard canAttemptSave() else {
            return false
        }

        var candidate = storedExercises

        switch mutation(&candidate) {
        case .persist:
            return persistAndPublish(candidate)

        case .succeededWithoutPersistence:
            return true

        case .rejected:
            return false
        }
    }

    // MARK: - Persistence

    private func load() {
        do {
            storedExercises = sorted(
                try repository.load()
            )

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

    private func canAttemptSave() -> Bool {
        guard isPersistenceWritable else {
            reportBlockedSave()
            return false
        }

        return true
    }

    private func persistAndPublish(
        _ exercises: [StoredCustomExercise]
    ) -> Bool {
        let candidate = sorted(
            exercises
        )

        do {
            try repository.save(
                candidate
            )

            storedExercises = candidate
            clearPersistenceError(for: .saving)

            return true
        } catch {
            print(
                "Failed to save custom exercises: \(error)"
            )

            setPersistenceError(
                operation: .saving,
                message:
                    "Couldn't save custom exercises."
            )

            return false
        }
    }

    // MARK: - Helpers

    private func sorted(
        _ exercises: [StoredCustomExercise]
    ) -> [StoredCustomExercise] {
        exercises.sorted {
            $0.exercise.name
                .localizedCaseInsensitiveCompare(
                    $1.exercise.name
                ) == .orderedAscending
        }
    }

    private func isDuplicateName(
        _ name: String,
        in exercises: [StoredCustomExercise],
        excluding exerciseID: UUID? = nil
    ) -> Bool {
        ExerciseNameValidator.validate(
            name,
            existingExercises:
                reservedExercises
                + exercises.map(\.exercise),
            excluding: exerciseID
        ) == .duplicate
    }
}
