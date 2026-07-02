import Foundation

final class UserSettingsStore: ObservableObject {
    @Published var settings: UserSettings

    private let key = "user_settings"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .defaults
            save()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    func replace(with newSettings: UserSettings) {
        settings = newSettings
        save()
    }
}
