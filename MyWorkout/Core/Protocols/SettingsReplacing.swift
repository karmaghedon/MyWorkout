import Foundation

@MainActor
protocol SettingsReplacing {
    func replace(
        with newSettings: UserSettings
    )
}

extension UserSettingsStore:
    SettingsReplacing {}
