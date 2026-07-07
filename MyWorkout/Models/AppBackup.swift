import Foundation

struct AppBackup: Codable {
    static let currentVersion = 1
    
    let version: Int
    let exportedAt: Date
    let logs: [WorkoutLog]
    let templates: [WorkoutTemplate]
    let equipment: EquipmentInventory
    let settings: UserSettings
}
