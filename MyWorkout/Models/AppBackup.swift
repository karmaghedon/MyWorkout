import Foundation

struct AppBackup: Codable {
    let version: Int
    let exportedAt: Date
    let logs: [WorkoutLog]
    let templates: [WorkoutTemplate]
    let equipment: EquipmentInventory
    let settings: UserSettings
}
