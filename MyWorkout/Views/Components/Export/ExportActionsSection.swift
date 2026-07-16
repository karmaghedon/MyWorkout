import SwiftUI

struct ExportActionsSection: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var settingsStore: UserSettingsStore
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var customExerciseStore: CustomExerciseStore

    @State private var showJSONExporter = false
    @State private var backupDocument = BackupDocument(backup: nil)

    @State private var showCSVExporter = false
    @State private var csvDocument = CSVDocument(text: "")

    @State private var exportResultMessage: String?
    @State private var showExportResult = false

    var body: some View {
        Section {
            Text("Export your workout history as a CSV file that can be opened in Excel, Numbers, or Google Sheets.")
                .foregroundStyle(.secondary)

            Button {
                csvDocument = CSVDocument(text: csvText())
                showCSVExporter = true
            } label: {
                Label("Export Workout History CSV", systemImage: "tablecells")
            }
            .fileExporter(
                isPresented: $showCSVExporter,
                document: csvDocument,
                contentType: .commaSeparatedText,
                defaultFilename: filename()
            ) { result in
                handleExportResult(result, label: "CSV export")
            }

            Button {
                backupDocument = BackupDocument(
                    backup: AppBackup(
                        version: AppBackup.currentVersion,
                        exportedAt: Date(),
                        logs: logStore.logs,
                        templates: templateStore.templates,
                        equipment: equipmentStore.inventory,
                        settings: settingsStore.settings,
                        customExercises: customExerciseStore.storedExercises
                    )
                )
                showJSONExporter = true
            } label: {
                Label("Export Full Backup JSON", systemImage: "arrow.down.doc.fill")
            }
            .accessibilityHint("Creates a JSON file containing all your workouts, templates, custom exercises, equipment, and settings.")
            .fileExporter(
                isPresented: $showJSONExporter,
                document: backupDocument,
                contentType: .json,
                defaultFilename: jsonFilename()
            ) { result in
                handleExportResult(result, label: "Backup export")
            }
        } header: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .alert(
            "Export Failed",
            isPresented: $showExportResult,
            presenting: exportResultMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>, label: String) {
        switch result {
        case .success(let url):
            print("\(label) succeeded: \(url)")
        case .failure(let error):
            let nsError = error as NSError

            // .fileExporter reports the user tapping Cancel as a failure
            // with this code, which isn't an actual error worth alerting on.
            guard nsError.domain != NSCocoaErrorDomain || nsError.code != NSUserCancelledError else {
                return
            }

            print("\(label) failed: \(error)")
            exportResultMessage = "\(label) couldn't be saved: \(error.localizedDescription)"
            showExportResult = true
        }
    }

    private func csvText() -> String {
        WorkoutCSVExporter.export(
            logs: logStore.logs,
            settings: settingsStore.settings
        )
    }

    private func filename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return "MyWorkout_History_\(formatter.string(from: Date())).csv"
    }

    private func jsonFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return "MyWorkout_Backup_\(formatter.string(from: Date())).json"
    }
}
