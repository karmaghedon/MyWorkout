import Foundation

@MainActor
final class UserSettingsStore: ObservableObject {
    @Published var settings: UserSettings
    @Published private(set) var lastSaveError: String?
    @Published private(set) var lastLoadError: String?

    private let key = "user_settings"

    init() {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                var loadedSettings = try JSONDecoder().decode(UserSettings.self, from: data)
                
                // Validate and clamp loaded settings
                loadedSettings = Self.validateSettings(loadedSettings)
                
                settings = loadedSettings
                lastLoadError = nil
            } catch {
                print("Failed to load settings: \(error)")
                settings = .defaults
                lastLoadError = "Couldn't load settings. Defaults were restored."
                save()
            }
        } else {
            settings = .defaults
            save()
        }
    }
    
    /// Validates and clamp a;; settings values to acceptable ranges.
    private static func validateSettings(_ settings: UserSettings) -> UserSettings {
        UserSettings(
            unitSystem: settings.unitSystem,
            compoundRestSeconds: InputValidation.clampRestDuration(settings.compoundRestSeconds),
            isolationRestSeconds: InputValidation.clampRestDuration(settings.isolationRestSeconds),
            bodyweightRestSeconds: InputValidation.clampRestDuration(settings.bodyweightRestSeconds),
            oneRepMaxFormula: settings.oneRepMaxFormula,
            compoundIncrement: max(1, min(settings.compoundIncrement, 25)),
            isolationIncrement: max(1, min(settings.isolationIncrement, 25))
        )
    }
    
    

    func save() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: key)
            lastSaveError = nil
        } catch {
            print("Failed to save settings: \(error)")
            lastSaveError = "Couldn't save settings."
        }
    }

    func replace(with newSettings: UserSettings) {
        settings = newSettings
        save()
    }
}
