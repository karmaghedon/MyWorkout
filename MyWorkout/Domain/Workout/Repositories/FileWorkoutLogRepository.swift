import Foundation

final class FileWorkoutLogRepository: WorkoutLogRepository {
    private static let currentSchemaVersion = 1

    private let fileURL: URL
    private let userDefaults: UserDefaults
    private let legacyDefaultsKey: String

    init(
        fileURL: URL,
        userDefaults: UserDefaults = .standard,
        legacyDefaultsKey: String = "workout_logs"
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

    // MARK: - WorkoutLogRepository

    func load() throws -> [WorkoutLog] {
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
        _ logs: [WorkoutLog]
    ) throws {
        try ensureDirectoryExists()

        let envelope = PersistedEnvelope(
            schemaVersion: Self.currentSchemaVersion,
            payload: logs
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

    private func loadFromFile() throws -> [WorkoutLog] {
        let data = try Data(
            contentsOf: fileURL
        )

        let decoder = JSONDecoder()

        if let envelope = try? decoder.decode(
            PersistedEnvelope<[WorkoutLog]>.self,
            from: data
        ) {
            guard envelope.schemaVersion
                    == Self.currentSchemaVersion else {
                throw FileWorkoutLogRepositoryError
                    .unsupportedSchemaVersion(
                        envelope.schemaVersion
                    )
            }

            return envelope.payload
        }

        /*
         Backward compatibility for workout_logs.json files
         saved before PersistedEnvelope was introduced.
         */
        let legacyLogs = try decoder.decode(
            [WorkoutLog].self,
            from: data
        )

        /*
         Rewrite the successfully decoded legacy array using
         the current versioned format.
         */
        try save(legacyLogs)

        return legacyLogs
    }

    // MARK: - Legacy UserDefaults Migration

    private func migrateLegacyDefaults(
        from data: Data
    ) throws -> [WorkoutLog] {
        let logs = try JSONDecoder().decode(
            [WorkoutLog].self,
            from: data
        )

        /*
         The legacy value is removed only after the new file
         has been written successfully.
         */
        try save(logs)

        userDefaults.removeObject(
            forKey: legacyDefaultsKey
        )

        return logs
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
                "workout_logs.json",
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

// MARK: - FileWorkoutLogRepositoryError

private enum FileWorkoutLogRepositoryError:
    LocalizedError {

    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return
                "Unsupported workout log schema version: "
                + "\(version)."
        }
    }
}
