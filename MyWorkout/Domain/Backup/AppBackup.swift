import Foundation

struct AppBackup: Codable {
    static let currentVersion = 2

    let version: Int
    let exportedAt: Date
    let logs: [WorkoutLog]
    let templates: [WorkoutTemplate]
    let equipment: EquipmentInventory
    let settings: UserSettings
    let customExercises: [StoredCustomExercise]

    init(
        version: Int = Self.currentVersion,
        exportedAt: Date,
        logs: [WorkoutLog],
        templates: [WorkoutTemplate],
        equipment: EquipmentInventory,
        settings: UserSettings,
        customExercises: [StoredCustomExercise] = []
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.logs = logs
        self.templates = templates
        self.equipment = equipment
        self.settings = settings
        self.customExercises = customExercises
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case exportedAt
        case logs
        case templates
        case equipment
        case settings
        case customExercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        version = try container.decode(
            Int.self,
            forKey: .version
        )
        exportedAt = try container.decode(
            Date.self,
            forKey: .exportedAt
        )
        logs = try container.decode(
            [WorkoutLog].self,
            forKey: .logs
        )
        templates = try container.decode(
            [WorkoutTemplate].self,
            forKey: .templates
        )
        equipment = try container.decode(
            EquipmentInventory.self,
            forKey: .equipment
        )
        settings = try container.decode(
            UserSettings.self,
            forKey: .settings
        )
        customExercises = try container.decodeIfPresent(
            [StoredCustomExercise].self,
            forKey: .customExercises
        ) ?? []
    }
}
