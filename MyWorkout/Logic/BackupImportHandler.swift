import Foundation

/// Outcome of attempting to import a backup file.
enum BackupImportResult {
    case success
    case unsupportedVersion(Int)
    case failure(String)
}

/// Decodes a backup JSON file and applies it to the app's stores.
///
/// Note on error handling: `replaceAll`/`replace` on the stores below are
/// synchronous, non-throwing calls — they update in-memory state immediately
/// and each store kicks off its own async save to disk afterward. That means
/// there's no way to roll back "if the replace fails," because it can't fail.
/// If the later on-disk save fails, that's surfaced separately through each
/// store's own `lastSaveError`, not through this import flow. A previous
/// version of this code wrapped the replace calls in a do/catch "rollback on
/// partial failure" block that could never actually run, which was more
/// misleading than helpful, so it's been removed. If synchronous,
/// all-or-nothing import persistence is needed later, that would mean giving
/// the stores a throwing, synchronous save path to call into here.
@MainActor
struct BackupImportHandler {
    let logStore: WorkoutLogStore
    let templateStore: WorkoutTemplateStore
    let equipmentStore: EquipmentInventoryStore
    let settingsStore: UserSettingsStore
    let customExerciseStore: CustomExerciseStore

    func importBackup(from url: URL) -> BackupImportResult {
        // Files handed back by .fileImporter may require security-scoped
        // access (e.g. files picked from iCloud Drive/Files); without this,
        // reading can silently fail for files outside the app's sandbox.
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let backup = try decoder.decode(AppBackup.self, from: data)

            guard backup.version <= AppBackup.currentVersion else {
                return .unsupportedVersion(backup.version)
            }

            logStore.replaceAll(with: backup.logs)
            templateStore.replaceAll(with: backup.templates)
            equipmentStore.replace(with: backup.equipment)
            settingsStore.replace(with: backup.settings)
            customExerciseStore.replaceAll(
                with: backup.customExercises
            )

            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}
