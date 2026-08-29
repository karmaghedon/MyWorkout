import SwiftUI

struct ImportActionsSection: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var settingsStore: UserSettingsStore
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var customExerciseStore: CustomExerciseStore

    @State private var showJSONImporter = false

    // Import is destructive (it replaces all local data), so a picked file
    // is held here and only actually applied after the user confirms.
    @State private var pendingImportURL: URL?
    @State private var showImportConfirmation = false

    @State private var importResultMessage: String?
    @State private var showImportResult = false

    private var importHandler: BackupImportHandler {
        BackupImportHandler(
            logStore: logStore,
            templateStore: templateStore,
            equipmentStore: equipmentStore,
            settingsStore: settingsStore,
            customExerciseStore: customExerciseStore
        )
    }

    var body: some View {
        Section {
            Button(role: .destructive) {
                showJSONImporter = true
            } label: {
                Label("Import Full Backup JSON", systemImage: "arrow.up.doc.fill")
            }
            .accessibilityHint("Replaces all current workouts, templates, custom exercises, equipment, and settings. You'll be asked to confirm before anything changes.")
            .fileImporter(
                isPresented: $showJSONImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    pendingImportURL = url
                    showImportConfirmation = true
                case .failure(let error):
                    importResultMessage = "Couldn't open that file: \(error.localizedDescription)"
                    showImportResult = true
                }
            }
        } header: {
            Label("Import", systemImage: "square.and.arrow.down")
        } footer: {
            Text("Importing replaces all current workouts, templates, custom exercises, equipment, and settings with the contents of the backup file. This can't be undone.")
        }
        .confirmationDialog(
            "Replace All Data?",
            isPresented: $showImportConfirmation,
            titleVisibility: .visible,
            presenting: pendingImportURL
        ) { url in
            Button("Replace Data", role: .destructive) {
                performImport(from: url)
                pendingImportURL = nil
            }

            Button("Cancel", role: .cancel) {
                pendingImportURL = nil
            }
        } message: { _ in
            Text("This will permanently replace all your current workouts, templates, custom exercises, equipment, and settings with the contents of this backup file.")
        }
        .alert(
            "Import Backup",
            isPresented: $showImportResult,
            presenting: importResultMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func performImport(from url: URL) {
        switch importHandler.importBackup(from: url) {
        case .success:
            importResultMessage = "Backup imported successfully."
        case .unsupportedVersion(let version):
            importResultMessage = "This backup was created by a newer version of the app (v\(version)). Update MyWorkout before importing."
        case .failure(let message):
            importResultMessage = "Failed to import backup: \(message)"
        }

        showImportResult = true
    }
}
