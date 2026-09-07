import Foundation

final class FileWorkoutTemplateRepository:
    WorkoutTemplateRepository {

    private static let currentSchemaVersion = 1

    private let fileURL: URL
    private let userDefaults: UserDefaults
    private let legacyDefaultsKey: String

    init(
        fileURL: URL,
        userDefaults: UserDefaults = .standard,
        legacyDefaultsKey: String = "workout_templates"
    ) {
        self.fileURL = fileURL
        self.userDefaults = userDefaults
        self.legacyDefaultsKey = legacyDefaultsKey
    }

    convenience init(
        userDefaults: UserDefaults = .standard
    ) {
        self.init(
            fileURL: Self.defaultFileURL(),
            userDefaults: userDefaults
        )
    }

    // MARK: - WorkoutTemplateRepository

    func load() throws -> [WorkoutTemplate] {
        if FileManager.default.fileExists(
            atPath: fileURL.path
        ) {
            return try loadFromFile()
        }

        if let legacyData = userDefaults.data(
            forKey: legacyDefaultsKey
        ) {
            return try migrateLegacyDefaults(
                from: legacyData
            )
        }

        return []
    }

    func save(
        _ templates: [WorkoutTemplate]
    ) throws {
        try ensureDirectoryExists()

        let envelope = PersistedEnvelope(
            schemaVersion: Self.currentSchemaVersion,
            payload: templates
        )

        let data = try JSONEncoder().encode(
            envelope
        )

        try data.write(
            to: fileURL,
            options: .atomic
        )
    }

    // MARK: - File Loading

    private func loadFromFile() throws
        -> [WorkoutTemplate] {

        let data = try Data(
            contentsOf: fileURL
        )

        let decoder = JSONDecoder()

        if let envelope = try? decoder.decode(
            PersistedEnvelope<[WorkoutTemplate]>.self,
            from: data
        ) {
            guard envelope.schemaVersion
                    == Self.currentSchemaVersion else {
                throw FileWorkoutTemplateRepositoryError
                    .unsupportedSchemaVersion(
                        envelope.schemaVersion
                    )
            }

            return envelope.payload
        }

        /*
         Backward compatibility for files written before
         PersistedEnvelope was introduced.
         */
        let legacyTemplates = try decoder.decode(
            [WorkoutTemplate].self,
            from: data
        )

        /*
         Rewrite the successfully decoded legacy array using
         the current versioned format.
         */
        try save(legacyTemplates)

        return legacyTemplates
    }

    // MARK: - Legacy UserDefaults Migration

    private func migrateLegacyDefaults(
        from data: Data
    ) throws -> [WorkoutTemplate] {

        let templates = try JSONDecoder().decode(
            [WorkoutTemplate].self,
            from: data
        )

        /*
         Remove the old value only after the versioned file
         has been written successfully.
         */
        try save(templates)

        userDefaults.removeObject(
            forKey: legacyDefaultsKey
        )

        return templates
    }

    // MARK: - File Location

    private static func defaultFileURL() -> URL {
        let fileManager = FileManager.default

        let applicationSupportDirectory =
            fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]

        return applicationSupportDirectory
            .appendingPathComponent(
                "MyWorkout",
                isDirectory: true
            )
            .appendingPathComponent(
                "workout_templates.json",
                isDirectory: false
            )
    }

    private func ensureDirectoryExists() throws {
        let directoryURL = fileURL
            .deletingLastPathComponent()

        guard !FileManager.default.fileExists(
            atPath: directoryURL.path
        ) else {
            return
        }

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }
}

// MARK: - FileWorkoutTemplateRepositoryError

private enum FileWorkoutTemplateRepositoryError:
    LocalizedError {

    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return
                "Unsupported workout template schema version: "
                + "\(version)."
        }
    }
}
