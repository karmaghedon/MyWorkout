import Foundation

@MainActor
final class WorkoutTemplateStore: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []

    @Published private(set) var persistenceError: StoreError?

    private let legacyDefaultsKey = "workout_templates"
    private let builtInRegistry: ExerciseRegistry

    private let fileURL: URL
    private let saveQueue = DispatchQueue(
        label: "com.myworkout.workouttemplatestore.save",
        qos: .utility
    )

    init(
        builtInRegistry: ExerciseRegistry = ExerciseRegistry(
            sources: [
                BuiltInExerciseSource()
            ]
        )
    ) {
        self.builtInRegistry = builtInRegistry

        fileURL = Self.resolveFileURL()
        load()

        if templates.isEmpty,
           persistenceError == nil {
            templates = SeedData.defaultTemplates
            save()
        }
    }

    func add(_ template: WorkoutTemplate) {
        templates.append(refreshed(template))
        save()
    }

    func delete(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
        save()
    }

    func update(_ template: WorkoutTemplate) {
        guard let index = templates.firstIndex(
            where: { $0.id == template.id }
        ) else {
            return
        }

        templates[index] = refreshed(template)
        save()
    }

    func duplicate(_ template: WorkoutTemplate) {
        let copy = WorkoutTemplate(
            id: UUID(),
            name: duplicateName(for: template.name),
            exercises: template.exercises
        )

        templates.append(copy)
        save()
    }

    func replaceAll(with newTemplates: [WorkoutTemplate]) {
        templates = newTemplates.map { refreshed($0) }
        save()
    }

    // MARK: - Persistence Errors

    func clearPersistenceError() {
        persistenceError = nil
    }
    
    private func duplicateName(for originalName: String) -> String {
        let baseName = "\(originalName) Copy"

        guard templates.contains(where: { $0.name == baseName }) else {
            return baseName
        }

        var copyNumber = 2

        while templates.contains(
            where: { $0.name == "\(baseName) \(copyNumber)" }
        ) {
            copyNumber += 1
        }

        return "\(baseName) \(copyNumber)"
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

    // MARK: - Persistence

    private static func resolveFileURL() -> URL {
        let fileManager = FileManager.default

        let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        let directory = appSupport.appendingPathComponent(
            "MyWorkout",
            isDirectory: true
        )

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }

        return directory.appendingPathComponent(
            "workout_templates.json"
        )
    }

    private func save() {
        let templatesToSave = templates
        let destination = fileURL

        saveQueue.async { [weak self] in
            do {
                let data = try JSONEncoder().encode(
                    templatesToSave
                )

                try data.write(
                    to: destination,
                    options: .atomic
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

    private func load() {
        if !FileManager.default.fileExists(
            atPath: fileURL.path
        ),
        let legacyData = UserDefaults.standard.data(
            forKey: legacyDefaultsKey
        ) {
            do {
                let decoded = try JSONDecoder().decode(
                    [WorkoutTemplate].self,
                    from: legacyData
                )

                templates = decoded.map { refreshed($0) }

                UserDefaults.standard.removeObject(
                    forKey: legacyDefaultsKey
                )

                clearPersistenceError(for: .loading)
                save()
            } catch {
                print(
                    "Failed to migrate legacy workout templates: \(error)"
                )

                setPersistenceError(
                    operation: .loading,
                    message:
                        "Couldn't load workout templates."
                )
            }

            return
        }

        guard FileManager.default.fileExists(
            atPath: fileURL.path
        ) else {
            clearPersistenceError(for: .loading)
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)

            let decoded = try JSONDecoder().decode(
                [WorkoutTemplate].self,
                from: data
            )

            templates = decoded.map { refreshed($0) }

            clearPersistenceError(for: .loading)

            // Save refreshed exercise definitions back to disk.
            save()
        } catch {
            print(
                "Failed to load workout templates: \(error)"
            )

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't load workout templates."
            )
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
