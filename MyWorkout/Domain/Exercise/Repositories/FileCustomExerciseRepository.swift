import Foundation

final class FileCustomExerciseRepository:
    CustomExerciseRepository {

    private static let currentSchemaVersion = 1

    private let fileURL: URL

    init(
        fileURL: URL
    ) {
        self.fileURL = fileURL
    }

    convenience init() {
        self.init(
            fileURL: Self.defaultFileURL()
        )
    }

    // MARK: - CustomExerciseRepository

    func load() throws -> [StoredCustomExercise] {
        guard FileManager.default.fileExists(
            atPath: fileURL.path
        ) else {
            return []
        }

        let data = try Data(
            contentsOf: fileURL
        )

        return try decodeExercises(
            from: data
        )
    }

    func save(
        _ exercises: [StoredCustomExercise]
    ) throws {
        try ensureDirectoryExists()

        let envelope = PersistedEnvelope(
            schemaVersion: Self.currentSchemaVersion,
            payload: exercises
        )

        let data = try JSONEncoder().encode(
            envelope
        )

        try data.write(
            to: fileURL,
            options: .atomic
        )
    }

    // MARK: - Decoding

    private func decodeExercises(
        from data: Data
    ) throws -> [StoredCustomExercise] {
        let decoder = JSONDecoder()

        if let envelope = try? decoder.decode(
            PersistedEnvelope<[StoredCustomExercise]>.self,
            from: data
        ) {
            guard envelope.schemaVersion
                    == Self.currentSchemaVersion else {
                throw FileCustomExerciseRepositoryError
                    .unsupportedSchemaVersion(
                        envelope.schemaVersion
                    )
            }

            return envelope.payload
        }

        /*
         Backward-compatible fallback for a possible
         pre-envelope custom exercise array.

         This format does not currently exist in production,
         but supporting it costs little and keeps the
         repository migration-friendly.
         */
        return try decoder.decode(
            [StoredCustomExercise].self,
            from: data
        )
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
                "custom_exercises.json",
                isDirectory: false
            )
    }

    private func ensureDirectoryExists() throws {
        let directoryURL =
            fileURL.deletingLastPathComponent()

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

// MARK: - FileCustomExerciseRepositoryError

private enum FileCustomExerciseRepositoryError:
    LocalizedError {

    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return
                "Unsupported custom exercise schema version: "
                + "\(version)."
        }
    }
}
