import Foundation

/// Same `PersistedEnvelope` + atomic-write pattern as
/// `FileMacroGoalRepository`/`FileBodyMeasurementLogRepository`. No legacy
/// pre-envelope or UserDefaults migration here — this domain has no history
/// to migrate from.
final class FileDailyNutritionLogRepository: DailyNutritionLogRepository {
    private static let currentSchemaVersion = 1

    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    convenience init() {
        self.init(fileURL: Self.defaultFileURL())
    }

    // MARK: - DailyNutritionLogRepository

    func load() throws -> [DailyNutritionLog] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        let envelope = try JSONDecoder().decode(
            PersistedEnvelope<[DailyNutritionLog]>.self,
            from: data
        )

        guard envelope.schemaVersion == Self.currentSchemaVersion else {
            throw FileDailyNutritionLogRepositoryError
                .unsupportedSchemaVersion(envelope.schemaVersion)
        }

        return envelope.payload
    }

    func save(
        _ logs: [DailyNutritionLog]
    ) throws {
        try ensureDirectoryExists()

        let envelope = PersistedEnvelope(
            schemaVersion: Self.currentSchemaVersion,
            payload: logs
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
            .appendingPathComponent("daily_nutrition_logs.json", isDirectory: false)
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

// MARK: - FileDailyNutritionLogRepositoryError

private enum FileDailyNutritionLogRepositoryError: LocalizedError {
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return "Unsupported daily nutrition log schema version: \(version)."
        }
    }
}
