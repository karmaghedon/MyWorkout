import Foundation

@MainActor
final class UserSettingsStore: ObservableObject {
    @Published var settings: UserSettings

    @Published private(set) var persistenceError: StoreError?

    private let key = "user_settings"

    init() {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                var loadedSettings = try JSONDecoder().decode(
                    UserSettings.self,
                    from: data
                )

                loadedSettings = Self.validateSettings(
                    loadedSettings
                )

                settings = loadedSettings
                clearPersistenceError(for: .loading)
            } catch {
                print(
                    "Failed to load settings: \(error)"
                )

                settings = .defaults

                setPersistenceError(
                    operation: .loading,
                    message:
                        "Couldn't load settings. "
                        + "Defaults were restored."
                )

                save()
            }
        } else {
            settings = .defaults
            save()
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

    /// Validates and clamps all settings values to acceptable ranges.
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
                )
        )
    }

    // MARK: - Persistence

    func save() {
        do {
            let data = try JSONEncoder().encode(settings)

            UserDefaults.standard.set(
                data,
                forKey: key
            )

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
        settings = newSettings
        save()
    }
}
