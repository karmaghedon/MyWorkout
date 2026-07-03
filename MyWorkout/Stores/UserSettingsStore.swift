import Foundation

final class UserSettingsStore: ObservableObject {
    @Published var settings: UserSettings
    @Published private(set) var lastSaveError: String?
    @Published private(set) var lastLoadError: String?

    private let key = "user_settings"

    init() {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                settings = try JSONDecoder().decode(UserSettings.self, from: data)
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
