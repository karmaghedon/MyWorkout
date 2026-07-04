import SwiftUI
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            text = string
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(
            regularFileWithContents: text.data(using: .utf8) ?? Data()
        )
    }
}

struct ExportView: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var settingsStore: UserSettingsStore
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore

    @State private var showJSONExporter = false
    @State private var showJSONImporter = false
    @State private var backupDocument = BackupDocument(backup: nil)

    @State private var showCSVExporter = false
    @State private var csvDocument = CSVDocument(text: "")

    // Import is destructive (it replaces all local data), so a picked file
    // is held here and only actually applied after the user confirms.
    @State private var pendingImportURL: URL?
    @State private var showImportConfirmation = false

    @State private var importResultMessage: String?
    @State private var showImportResult = false

    var body: some View {
        Form {
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
                    switch result {
                    case .success(let url):
                        print("CSV exported to: \(url)")
                    case .failure(let error):
                        print("Failed to export CSV: \(error)")
                    }
                }

                Button {
                    backupDocument = BackupDocument(
                        backup: AppBackup(
                            version: 1,
                            exportedAt: Date(),
                            logs: logStore.logs,
                            templates: templateStore.templates,
                            equipment: equipmentStore.inventory,
                            settings: settingsStore.settings
                        )
                    )
                    showJSONExporter = true
                } label: {
                    Label("Export Full Backup JSON", systemImage: "arrow.down.doc.fill")
                }
                .fileExporter(
                    isPresented: $showJSONExporter,
                    document: backupDocument,
                    contentType: .json,
                    defaultFilename: jsonFilename()
                ) { result in
                    switch result {
                    case .success(let url):
                        print("JSON backup exported to: \(url)")
                    case .failure(let error):
                        print("Failed to export JSON backup: \(error)")
                    }
                }
            } header: {
                Label("Export", systemImage: "square.and.arrow.up")
            }

            Section {
                Button(role: .destructive) {
                    showJSONImporter = true
                } label: {
                    Label("Import Full Backup JSON", systemImage: "arrow.up.doc.fill")
                }
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
                Text("Importing replaces all current workouts, templates, equipment, and settings with the contents of the backup file. This can't be undone.")
            }
        }
        .navigationTitle("Backup & Export")
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
            Text("This will permanently replace all your current workouts, templates, equipment, and settings with the contents of this backup file.")
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

    private func performImport(from url: URL) {
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

            logStore.replaceAll(with: backup.logs)
            templateStore.replaceAll(with: backup.templates)
            equipmentStore.replace(with: backup.equipment)
            settingsStore.replace(with: backup.settings)

            importResultMessage = "Backup imported successfully."
        } catch {
            importResultMessage = "Failed to import backup: \(error.localizedDescription)"
        }

        showImportResult = true
    }
}
