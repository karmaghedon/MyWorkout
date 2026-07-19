import Foundation

@MainActor
final class WorkoutTemplateStore: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []

    @Published private(set) var persistenceError: StoreError?

    private let repository: any WorkoutTemplateRepository
    private let builtInRegistry: ExerciseRegistry

    private let saveQueue = DispatchQueue(
        label: "com.myworkout.workouttemplatestore.save",
        qos: .utility
    )

    /// Prevents unreadable persisted templates from being overwritten.
    private var isPersistenceWritable = true

    init(
        repository: any WorkoutTemplateRepository =
            FileWorkoutTemplateRepository(),
        builtInRegistry: ExerciseRegistry = ExerciseRegistry(
            sources: [
                BuiltInExerciseSource()
            ]
        )
    ) {
        self.repository = repository
        self.builtInRegistry = builtInRegistry

        load()

        if templates.isEmpty,
           persistenceError == nil {
            templates = SeedData.defaultTemplates.map {
                refreshed($0)
            }

            save()
        }
    }

    // MARK: - Template Actions

    func add(_ template: WorkoutTemplate) {
        templates.append(
            refreshed(template)
        )

        save()
    }

    func delete(at offsets: IndexSet) {
        templates.remove(
            atOffsets: offsets
        )

        save()
    }

    func update(_ template: WorkoutTemplate) {
        guard let index = templates.firstIndex(
            where: { $0.id == template.id }
        ) else {
            return
        }

        templates[index] = refreshed(
            template
        )

        save()
    }

    func duplicate(_ template: WorkoutTemplate) {
        let copy = WorkoutTemplate(
            id: UUID(),
            name: duplicateName(
                for: template.name
            ),
            exercises: template.exercises
        )

        templates.append(
            refreshed(copy)
        )

        save()
    }

    func replaceAll(
        with newTemplates: [WorkoutTemplate]
    ) {
        templates = newTemplates.map {
            refreshed($0)
        }

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
        guard persistenceError?.operation
                == operation else {
            return
        }

        persistenceError = nil
    }

    // MARK: - Duplicate Naming

    private func duplicateName(
        for originalName: String
    ) -> String {
        let baseName =
            "\(originalName) Copy"

        guard templates.contains(
            where: {
                $0.name == baseName
            }
        ) else {
            return baseName
        }

        var copyNumber = 2

        while templates.contains(
            where: {
                $0.name
                    == "\(baseName) \(copyNumber)"
            }
        ) {
            copyNumber += 1
        }

        return
            "\(baseName) \(copyNumber)"
    }

    // MARK: - Persistence

    private func load() {
        do {
            let loadedTemplates =
                try repository.load()

            templates = loadedTemplates.map {
                refreshed($0)
            }

            isPersistenceWritable = true

            clearPersistenceError(
                for: .loading
            )
        } catch {
            isPersistenceWritable = false

            print(
                "Failed to load workout templates: \(error)"
            )

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't load your workout templates. "
                    + "The existing template data was preserved "
                    + "and will not be overwritten."
            )
        }
    }

    private func save() {
        guard isPersistenceWritable else {
            setPersistenceError(
                operation: .saving,
                message:
                    "Your workout templates could not be read, "
                    + "so they were not overwritten. Restart "
                    + "the app or restore a valid backup before "
                    + "saving more templates."
            )

            return
        }

        let templatesToSave = templates
        let repository = repository

        saveQueue.async { [weak self] in
            do {
                try repository.save(
                    templatesToSave
                )

                DispatchQueue.main.async {
                    self?.clearPersistenceError(
                        for: .saving
                    )
                }
            } catch {
                print(
                    "Failed to save workout templates: \(error)"
                )

                DispatchQueue.main.async {
                    self?.setPersistenceError(
                        operation: .saving,
                        message:
                            "Couldn't save workout templates."
                    )
                }
            }
        }
    }

    // MARK: - Exercise Refresh

    private func refreshed(
        _ template: WorkoutTemplate
    ) -> WorkoutTemplate {
        WorkoutTemplate(
            id: template.id,
            name: template.name,
            exercises: template.exercises.map {
                savedExercise in

                builtInRegistry.exercise(
                    id: savedExercise.id,
                    name: savedExercise.name
                ) ?? savedExercise
            }
        )
    }
}
