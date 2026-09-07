import Foundation

@MainActor
final class UserSettingsStore: ObservableObject {
    @Published var settings: UserSettings

    @Published private(set) var persistenceError: StoreError?

    private static let currentSchemaVersion = 1

    /// The pre-file-based-persistence key: `UserDefaults.set()` only
    /// updates the in-memory cache synchronously, the actual disk
    /// write-back happens on the OS's own schedule — and, contrary to
    /// its name, `UserDefaults.synchronize()` does not force that
    /// (Apple's own documentation calls it "unnecessary" precisely
    /// because it no longer does anything on modern iOS). That made a
    /// kill shortly after changing a setting silently lose it, since
    /// nothing could guarantee the write had landed. Confirmed on
    /// device before this fix. Settings now persist to a real file
    /// instead (see `fileURL`), written synchronously and atomically —
    /// this key is kept only as a one-time migration source for
    /// whatever's already stored there from before this change.
    private static let legacyUserDefaultsKey = "user_settings"

    private let fileURL: URL
    private let legacyUserDefaults: UserDefaults

    /// Prevents unreadable settings from being overwritten.
    private var isPersistenceWritable = true

    init(
        fileURL: URL = UserSettingsStore.defaultFileURL(),
        legacyUserDefaults: UserDefaults = .standard
    ) {
        self.fileURL = fileURL
        self.legacyUserDefaults = legacyUserDefaults

        guard let data = Self.readData(fileURL: fileURL, legacyUserDefaults: legacyUserDefaults) else {
            settings = .defaults
            save()
            return
        }

        do {
            let decodedResult = try Self.decodeSettings(
                from: data.payload
            )

            settings = Self.validateSettings(
                decodedResult.settings
            )

            isPersistenceWritable = true
            clearPersistenceError(for: .loading)

            if decodedResult.requiresMigration || data.isFromLegacyLocation {
                save()
            }
        } catch {
            print(
                "Failed to load settings: \(error)"
            )

            /*
             Keep the original persisted value untouched.
             Do not replace it automatically with defaults.
             */
            settings = .defaults
            isPersistenceWritable = false

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't load your saved settings. "
                    + "Defaults are being used temporarily, "
                    + "and the existing data was preserved."
            )
        }
    }

    /// Reads from the current file location first; falls back to the
    /// legacy `UserDefaults` key only if the file doesn't exist yet
    /// (i.e. this is the first launch since the persistence backend
    /// changed), so a real settings value from before this change
    /// still gets picked up exactly once instead of silently resetting
    /// to defaults.
    private static func readData(
        fileURL: URL,
        legacyUserDefaults: UserDefaults
    ) -> (payload: Data, isFromLegacyLocation: Bool)? {
        if let fileData = try? Data(contentsOf: fileURL) {
            return (fileData, false)
        }

        guard let legacyData = legacyUserDefaults.data(forKey: legacyUserDefaultsKey) else {
            return nil
        }

        return (legacyData, true)
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

    // MARK: - Validation

    private static func validateSettings(
        _ settings: UserSettings
    ) -> UserSettings {
        UserSettings(
            unitSystem: settings.unitSystem,
            bodyWeightUnitSystem: settings.bodyWeightUnitSystem,
            biologicalSex: settings.biologicalSex,
            heightCm: settings.heightCm,
            compoundRestSeconds:
                InputValidation.clampRestDuration(
                    settings.compoundRestSeconds
                ),
            isolationRestSeconds:
                InputValidation.clampRestDuration(
                    settings.isolationRestSeconds
                ),
            bodyweightRestSeconds:
                InputValidation.clampRestDuration(
                    settings.bodyweightRestSeconds
                ),
            oneRepMaxFormula:
                settings.oneRepMaxFormula,
            compoundIncrement:
                max(
                    1,
                    min(settings.compoundIncrement, 25)
                ),
            isolationIncrement:
                max(
                    1,
                    min(settings.isolationIncrement, 25)
                ),
            appearanceMode:
                settings.appearanceMode,
            workoutSessionLayout:
                settings.workoutSessionLayout,
            restTimerSound:
                settings.restTimerSound
        )
    }

    // MARK: - Persistence

    func save() {
        guard isPersistenceWritable else {
            setPersistenceError(
                operation: .saving,
                message:
                    "Settings could not be saved because "
                    + "the existing saved data could not be read."
            )
            return
        }

        do {
            try ensureDirectoryExists()

            let validatedSettings = Self.validateSettings(
                settings
            )

            let envelope = PersistedEnvelope(
                schemaVersion: Self.currentSchemaVersion,
                payload: validatedSettings
            )

            let data = try JSONEncoder().encode(
                envelope
            )

            // Atomic, synchronous — unlike the old UserDefaults-backed
            // save, this genuinely blocks until the write has landed on
            // disk, so there's nothing left to flush before the app
            // backgrounds or terminates.
            try data.write(
                to: fileURL,
                options: .atomic
            )

            settings = validatedSettings
            clearPersistenceError(for: .saving)
        } catch {
            print(
                "Failed to save settings: \(error)"
            )

            setPersistenceError(
                operation: .saving,
                message:
                    "Couldn't save settings."
            )
        }
    }

    // MARK: - File Location

    /// `nonisolated` so it can be used as a default parameter value in
    /// `init` — a `@MainActor`-isolated static function can't be
    /// referenced there, even though this one is a pure, stateless URL
    /// computation with no actual dependency on main-actor state.
    private nonisolated static func defaultFileURL() -> URL {
        let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return applicationSupportDirectory
            .appendingPathComponent("MyWorkout", isDirectory: true)
            .appendingPathComponent("user_settings.json", isDirectory: false)
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

    func replace(
        with newSettings: UserSettings
    ) {
        guard isPersistenceWritable else {
            setPersistenceError(
                operation: .saving,
                message:
                    "Settings could not be replaced because "
                    + "the existing saved data could not be read."
            )
            return
        }

        settings = Self.validateSettings(
            newSettings
        )

        save()
    }

    // MARK: - Decoding

    private static func decodeSettings(
        from data: Data
    ) throws -> DecodedSettings {
        let decoder = JSONDecoder()

        /*
         Only treat the data as the legacy unwrapped format when it isn't
         shaped like an envelope at all. If it has envelope keys but the
         payload fails to decode (e.g. a corrupted or unrecognized field
         value), that must surface as a real failure rather than falling
         through to the legacy path — the legacy `UserSettings` decoder
         is tolerant-by-design (every field defaults via
         `decodeIfPresent(...) ?? defaults`), so handing it envelope-shaped
         JSON would silently "succeed" with all-default settings and then
         immediately persist that wipe over the user's real data.
         */
        if isEnvelopeShaped(data) {
            let envelope = try decoder.decode(
                PersistedEnvelope<UserSettings>.self,
                from: data
            )

            guard envelope.schemaVersion
                    == currentSchemaVersion else {
                throw UserSettingsPersistenceError
                    .unsupportedSchemaVersion(
                        envelope.schemaVersion
                    )
            }

            return DecodedSettings(
                settings: envelope.payload,
                requiresMigration: false
            )
        }

        /*
         Backward compatibility for the original unwrapped
         UserSettings value stored in UserDefaults.
         */
        let legacySettings = try decoder.decode(
            UserSettings.self,
            from: data
        )

        return DecodedSettings(
            settings: legacySettings,
            requiresMigration: true
        )
    }

    /// Case-insensitive on purpose: this only has to recognize the data as
    /// *shaped like* an envelope, not successfully decode it. Matching
    /// exact-case `"schemaVersion"`/`"payload"` would let anything with
    /// slightly different key casing (e.g. `"Payload"`) fall through to
    /// the tolerant legacy path below and silently wipe real settings —
    /// the same failure mode this whole function exists to prevent. The
    /// strict `PersistedEnvelope` decode a few lines up still enforces
    /// exact key casing; a genuine mismatch throws there and is preserved
    /// by the caller's `catch`, rather than vanishing here.
    private static func isEnvelopeShaped(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any] else {
            return false
        }

        let keys = Set(object.keys.map { $0.lowercased() })

        return keys.contains("schemaversion")
            && keys.contains("payload")
    }
}

// MARK: - DecodedSettings

private struct DecodedSettings {
    let settings: UserSettings
    let requiresMigration: Bool
}

// MARK: - UserSettingsPersistenceError

private enum UserSettingsPersistenceError:
    LocalizedError {

    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return
                "Unsupported user-settings schema version: "
                + "\(version)."
        }
    }
}
