import Foundation

/// Same `PersistedEnvelope` + atomic-write pattern as
/// `FileWorkoutLogRepository`/`FileWorkoutTemplateRepository`. No legacy
/// pre-envelope or UserDefaults migration here — unlike those older
/// domains, this one has no history to migrate from, so that scaffolding
/// would never trigger.
final class FileBodyMeasurementLogRepository: BodyMeasurementLogRepository {
    private static let currentSchemaVersion = 1

    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    convenience init() {
        self.init(fileURL: Self.defaultFileURL())
    }

    // MARK: - BodyMeasurementLogRepository

    func load() throws -> [BodyMeasurementLog] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        let envelope = try JSONDecoder().decode(
            PersistedEnvelope<[BodyMeasurementLog]>.self,
            from: data
        )

        guard envelope.schemaVersion == Self.currentSchemaVersion else {
            throw FileBodyMeasurementLogRepositoryError
                .unsupportedSchemaVersion(envelope.schemaVersion)
        }

        return envelope.payload
    }

    func save(
        _ logs: [BodyMeasurementLog]
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
            .appendingPathComponent("body_measurement_logs.json", isDirectory: false)
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

// MARK: - FileBodyMeasurementLogRepositoryError

private enum FileBodyMeasurementLogRepositoryError: LocalizedError {
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return "Unsupported body measurement log schema version: \(version)."
        }
    }
}
