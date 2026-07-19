import Foundation

// MARK: - Persisted Models

/// The persisted representation of an active workout.
///
/// Snapshot versioning and migration belong to Phase 4.
/// For Phase 3.1, this intentionally preserves the existing JSON structure.

enum ActiveWorkoutPersistenceError: LocalizedError {
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return """
            Active workout schema version \(version) is newer than \
            the supported version \
            \(ActiveWorkoutSnapshot.currentSchemaVersion).
            """
        }
    }
}

struct ActiveWorkoutSnapshot: Codable {

    // MARK: - Schema

    static let currentSchemaVersion = 1

    let schemaVersion: Int

    // MARK: - Persisted Workout State

    let activeWorkout: Workout
    let exerciseStates: [ExerciseStateSnapshot]
    let startedAt: Date?
    let activeRestExerciseID: UUID?
    let restStartedAt: Date?
    let restTotalSeconds: Int

    // MARK: - Initialization

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        activeWorkout: Workout,
        exerciseStates: [ExerciseStateSnapshot],
        startedAt: Date?,
        activeRestExerciseID: UUID?,
        restStartedAt: Date?,
        restTotalSeconds: Int
    ) {
        self.schemaVersion = schemaVersion
        self.activeWorkout = activeWorkout
        self.exerciseStates = exerciseStates
        self.startedAt = startedAt
        self.activeRestExerciseID = activeRestExerciseID
        self.restStartedAt = restStartedAt
        self.restTotalSeconds = restTotalSeconds
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case activeWorkout
        case exerciseStates
        case startedAt
        case activeRestExerciseID
        case restStartedAt
        case restTotalSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        // Snapshots created before schema versioning are considered v1.
        let decodedVersion = try container.decodeIfPresent(
            Int.self,
            forKey: .schemaVersion
        ) ?? 1

        guard decodedVersion <= Self.currentSchemaVersion else {
            throw ActiveWorkoutPersistenceError.unsupportedSchemaVersion(
                decodedVersion
            )
        }

        schemaVersion = decodedVersion

        activeWorkout = try container.decode(
            Workout.self,
            forKey: .activeWorkout
        )

        exerciseStates = try container.decode(
            [ExerciseStateSnapshot].self,
            forKey: .exerciseStates
        )

        startedAt = try container.decodeIfPresent(
            Date.self,
            forKey: .startedAt
        )

        activeRestExerciseID = try container.decodeIfPresent(
            UUID.self,
            forKey: .activeRestExerciseID
        )

        restStartedAt = try container.decodeIfPresent(
            Date.self,
            forKey: .restStartedAt
        )

        restTotalSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .restTotalSeconds
        ) ?? 0
    }
}

struct ExerciseStateSnapshot: Codable {
    let exerciseID: UUID
    let state: ExerciseSessionState
}

// MARK: - Persistence Contract

protocol ActiveWorkoutPersisting {
    func save(_ snapshot: ActiveWorkoutSnapshot) throws
    func load() throws -> ActiveWorkoutSnapshot?
    func delete() throws
}

// MARK: - File Persistence

final class FileActiveWorkoutPersistence: ActiveWorkoutPersisting {
    private let fileURL: URL
    private let legacyDefaults: UserDefaults
    private let legacyDefaultsKey: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(
        fileManager: FileManager = .default,
        legacyDefaults: UserDefaults = .standard,
        legacyDefaultsKey: String = "active_workout_session",
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.fileManager = fileManager
        self.legacyDefaults = legacyDefaults
        self.legacyDefaultsKey = legacyDefaultsKey
        self.encoder = encoder
        self.decoder = decoder
        self.fileURL = Self.resolveFileURL(using: fileManager)
    }

    func save(_ snapshot: ActiveWorkoutSnapshot) throws {
        try ensureParentDirectoryExists()

        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> ActiveWorkoutSnapshot? {
        if fileManager.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)

            return try decoder.decode(
                ActiveWorkoutSnapshot.self,
                from: data
            )
        }

        guard let legacyData = legacyDefaults.data(
            forKey: legacyDefaultsKey
        ) else {
            return nil
        }

        let snapshot = try decoder.decode(
            ActiveWorkoutSnapshot.self,
            from: legacyData
        )

        // Only remove the legacy value after the file copy succeeds.
        try save(snapshot)
        legacyDefaults.removeObject(forKey: legacyDefaultsKey)

        return snapshot
    }

    func delete() throws {
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }

        // Also clear any obsolete legacy session so a cancelled workout
        // cannot reappear from UserDefaults on a future launch.
        legacyDefaults.removeObject(forKey: legacyDefaultsKey)
    }

    private func ensureParentDirectoryExists() throws {
        let directory = fileURL.deletingLastPathComponent()

        guard !fileManager.fileExists(atPath: directory.path) else {
            return
        }

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    private static func resolveFileURL(
        using fileManager: FileManager
    ) -> URL {
        let applicationSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return applicationSupportDirectory
            .appendingPathComponent("MyWorkout", isDirectory: true)
            .appendingPathComponent("active_workout_session.json")
    }
}
