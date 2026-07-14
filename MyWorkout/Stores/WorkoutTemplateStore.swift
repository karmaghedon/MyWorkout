import Foundation

@MainActor
final class WorkoutTemplateStore: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []

    @Published private(set) var persistenceError: StoreError?

    private static let currentSchemaVersion = 1

    private let legacyDefaultsKey = "workout_templates"
    private let builtInRegistry: ExerciseRegistry

    private let fileURL: URL
    private let saveQueue = DispatchQueue(
        label: "com.myworkout.workouttemplatestore.save",
        qos: .utility
    )

    /// Prevents an unreadable template file from being overwritten.
    private var isPersistenceWritable = true

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

    // MARK: - Template Actions

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

        templates.append(refreshed(copy))
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
        guard persistenceError?.operation == operation else {
            return
        }

        persistenceError = nil
    }

    // MARK: - Duplicate Naming

    private func duplicateName(
        for originalName: String
    ) -> String {
        let baseName = "\(originalName) Copy"

        guard templates.contains(
            where: { $0.name == baseName }
        ) else {
            return baseName
        }

        var copyNumber = 2

        while templates.contains(
            where: {
                $0.name == "\(baseName) \(copyNumber)"
            }
        ) {
            copyNumber += 1
        }

        return "\(baseName) \(copyNumber)"
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

        if !fileManager.fileExists(
            atPath: directory.path
        ) {
            try? fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }

        return directory.appendingPathComponent(
            "workout_templates.json"
        )
    }

    private func save(
        onSuccess: (() -> Void)? = nil
    ) {
        guard isPersistenceWritable else {
            setPersistenceError(
                operation: .saving,
                message:
                    "Your workout templates could not be read, "
                    + "so the existing file was not overwritten. "
                    + "Restart the app or restore a valid backup "
                    + "before saving more templates."
            )

            return
        }

        let envelope = PersistedEnvelope(
            schemaVersion: Self.currentSchemaVersion,
            payload: templates
        )

        let destination = fileURL

        saveQueue.async { [weak self] in
            do {
                let data = try JSONEncoder().encode(
                    envelope
                )

                try data.write(
                    to: destination,
                    options: .atomic
                )

                DispatchQueue.main.async {
                    self?.clearPersistenceError(
                        for: .saving
                    )

                    onSuccess?()
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
            migrateLegacyDefaults(
                from: legacyData
            )

            return
        }

        guard FileManager.default.fileExists(
            atPath: fileURL.path
        ) else {
            isPersistenceWritable = true
            clearPersistenceError(for: .loading)
            return
        }

        do {
            let data = try Data(
                contentsOf: fileURL
            )

            let decodedTemplates = try decodeTemplates(
                from: data
            )

            templates = decodedTemplates.map {
                refreshed($0)
            }

            isPersistenceWritable = true
            clearPersistenceError(for: .loading)

            /*
             Re-save after loading because:
             1. Legacy unwrapped files need migration.
             2. Stored exercise definitions may have been refreshed
                from the built-in exercise registry.
             */
            save()
        } catch {
            isPersistenceWritable = false

            print(
                "Failed to load workout templates: \(error)"
            )

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't load your workout templates. "
                    + "The existing template file was preserved "
                    + "and will not be overwritten."
            )
        }
    }

    private func migrateLegacyDefaults(
        from data: Data
    ) {
        do {
            let decodedTemplates = try JSONDecoder().decode(
                [WorkoutTemplate].self,
                from: data
            )

            templates = decodedTemplates.map {
                refreshed($0)
            }

            isPersistenceWritable = true
            clearPersistenceError(for: .loading)

            /*
             Remove the legacy value only after the new file
             has been written successfully.
             */
            save {
                UserDefaults.standard.removeObject(
                    forKey: self.legacyDefaultsKey
                )
            }
        } catch {
            isPersistenceWritable = false

            print(
                "Failed to migrate legacy workout templates: \(error)"
            )

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't migrate your saved workout templates. "
                    + "The original data was preserved."
            )
        }
    }

    private func decodeTemplates(
        from data: Data
    ) throws -> [WorkoutTemplate] {
        let decoder = JSONDecoder()

        if let envelope = try? decoder.decode(
            PersistedEnvelope<[WorkoutTemplate]>.self,
            from: data
        ) {
            guard envelope.schemaVersion
                    == Self.currentSchemaVersion else {
                throw WorkoutTemplatePersistenceError
                    .unsupportedSchemaVersion(
                        envelope.schemaVersion
                    )
            }

            return envelope.payload
        }

        /*
         Backward compatibility for workout_templates.json
         files saved before PersistedEnvelope was introduced.
         */
        return try decoder.decode(
            [WorkoutTemplate].self,
            from: data
        )
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

// MARK: - WorkoutTemplatePersistenceError

private enum WorkoutTemplatePersistenceError:
    LocalizedError {
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return
                "Unsupported workout template schema "
                + "version: \(version)."
        }
    }
}
