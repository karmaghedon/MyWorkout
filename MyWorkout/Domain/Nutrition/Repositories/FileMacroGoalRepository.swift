import Foundation

/// Same `PersistedEnvelope` + atomic-write pattern as
/// `FileBodyMeasurementLogRepository`/`FileWorkoutLogRepository`. No legacy
/// pre-envelope or UserDefaults migration here — this domain has no history
/// to migrate from.
final class FileMacroGoalRepository: MacroGoalRepository {
    private static let currentSchemaVersion = 1

    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    convenience init() {
        self.init(fileURL: Self.defaultFileURL())
    }

    // MARK: - MacroGoalRepository

    func load() throws -> [MacroGoal] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        let envelope = try JSONDecoder().decode(
            PersistedEnvelope<[MacroGoal]>.self,
            from: data
        )

        guard envelope.schemaVersion == Self.currentSchemaVersion else {
            throw FileMacroGoalRepositoryError
                .unsupportedSchemaVersion(envelope.schemaVersion)
        }

        return envelope.payload
    }

    func save(
        _ goals: [MacroGoal]
    ) throws {
        try ensureDirectoryExists()

        let envelope = PersistedEnvelope(
            schemaVersion: Self.currentSchemaVersion,
            payload: goals
        )

        let data = try JSONEncoder().encode(envelope)

        try data.write(
            to: fileURL,
            options: .atomic
        )
    }

    // MARK: - File Location

    private static func defaultFileURL() -> URL {
        let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return applicationSupportDirectory
            .appendingPathComponent("MyWorkout", isDirectory: true)
            .appendingPathComponent("macro_goals.json", isDirectory: false)
    }

    private func ensureDirectoryExists() throws {
        let directoryURL = fileURL.deletingLastPathComponent()

        guard !FileManager.default.fileExists(atPath: directoryURL.path) else {
            return
        }

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }
}

// MARK: - FileMacroGoalRepositoryError

private enum FileMacroGoalRepositoryError: LocalizedError {
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return "Unsupported macro goal schema version: \(version)."
        }
    }
}
