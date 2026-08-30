import Foundation

/// Outcome of attempting to import a backup file.
enum BackupImportResult {
    case success
    case unsupportedVersion(Int)
    case failure(String)
}

/// Decodes a backup JSON file, validates it, and applies it to the app's stores.
///
/// Backup validation happens before any store is modified. Store replacement is
/// still synchronous and non-throwing, so a later persistence failure is
/// surfaced by the affected store rather than rolled back here.
@MainActor
struct BackupImportHandler {
    let logStore: any WorkoutLogReplacing
    let templateStore: any WorkoutTemplateReplacing
    let equipmentStore: any EquipmentReplacing
    let settingsStore: any SettingsReplacing
    let customExerciseStore: any CustomExerciseReplacing
    let bodyMeasurementLogStore: any BodyMeasurementLogReplacing
    let macroGoalStore: any MacroGoalReplacing

    func importBackup(
        from url: URL
    ) -> BackupImportResult {
        let didStartAccessing =
            url.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(
                contentsOf: url
            )

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let backup = try decoder.decode(
                AppBackup.self,
                from: data
            )

            guard backup.version
                    <= AppBackup.currentVersion else {
                return .unsupportedVersion(
                    backup.version
                )
            }

            let customExerciseValidation =
                CustomExerciseImportValidator.validate(
                    backup.customExercises,
                    reservedExercises:
                        SeedData.exercises
                )

            guard customExerciseValidation
                    == .valid else {
                return .failure(
                    customExerciseValidation.message
                    ?? "The backup contains invalid custom exercises."
                )
            }

            logStore.replaceAll(
                with: backup.logs
            )

            templateStore.replaceAll(
                with: backup.templates
            )

            equipmentStore.replace(
                with: backup.equipment
            )

            settingsStore.replace(
                with: backup.settings
            )

            guard customExerciseStore.replaceAll(
                with: backup.customExercises
            ) else {
                return .failure(
                    customExerciseStore
                        .persistenceError?
                        .message
                    ?? "Custom exercises could not be imported."
                )
            }

            bodyMeasurementLogStore.replaceAll(
                with: backup.bodyMeasurementLogs
            )

            macroGoalStore.replaceAll(
                with: backup.macroGoals
            )

            return .success
        } catch {
            return .failure(
                error.localizedDescription
            )
        }
    }
}
