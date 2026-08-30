import Foundation

struct AppBackup: Codable {
    static let currentVersion = 3

    let version: Int
    let exportedAt: Date
    let logs: [WorkoutLog]
    let templates: [WorkoutTemplate]
    let equipment: EquipmentInventory
    let settings: UserSettings
    let customExercises: [StoredCustomExercise]
    /// HealthKit-resident body metrics (weight, body fat %, waist) are
    /// deliberately not part of this backup — they already live in
    /// HealthKit/iCloud. Neck has no HealthKit type, so it's the one
    /// body-metrics field backed up here.
    let bodyMeasurementLogs: [BodyMeasurementLog]

    init(
        version: Int = Self.currentVersion,
        exportedAt: Date,
        logs: [WorkoutLog],
        templates: [WorkoutTemplate],
        equipment: EquipmentInventory,
        settings: UserSettings,
        customExercises: [StoredCustomExercise] = [],
        bodyMeasurementLogs: [BodyMeasurementLog] = []
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.logs = logs
        self.templates = templates
        self.equipment = equipment
        self.settings = settings
        self.customExercises = customExercises
        self.bodyMeasurementLogs = bodyMeasurementLogs
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case exportedAt
        case logs
        case templates
        case equipment
        case settings
        case customExercises
        case bodyMeasurementLogs
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
        bodyMeasurementLogs = try container.decodeIfPresent(
            [BodyMeasurementLog].self,
            forKey: .bodyMeasurementLogs
        ) ?? []
    }
}
