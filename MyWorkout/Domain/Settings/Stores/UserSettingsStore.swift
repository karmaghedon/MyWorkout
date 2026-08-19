import Foundation

@MainActor
final class UserSettingsStore: ObservableObject {
    @Published var settings: UserSettings

    @Published private(set) var persistenceError: StoreError?

    private static let currentSchemaVersion = 1

    private let key = "user_settings"

    /// Prevents unreadable settings from being overwritten.
    private var isPersistenceWritable = true

    init() {
        guard let data = UserDefaults.standard.data(
            forKey: key
        ) else {
            settings = .defaults
            save()
            return
        }

        do {
            let decodedResult = try Self.decodeSettings(
                from: data
            )

            settings = Self.validateSettings(
                decodedResult.settings
            )

            isPersistenceWritable = true
            clearPersistenceError(for: .loading)

            if decodedResult.requiresMigration {
                save()
            }
        } catch {
            print(
                "Failed to load settings: \(error)"
            )

            /*
             Keep the original UserDefaults value untouched.
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
                settings.appearanceMode
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

            UserDefaults.standard.set(
                data,
                forKey: key
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

        if let envelope = try? decoder.decode(
            PersistedEnvelope<UserSettings>.self,
            from: data
        ) {
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
