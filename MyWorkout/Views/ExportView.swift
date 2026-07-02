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

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Export")
                .font(AppTheme.Typography.sectionTitle)

            Text("Export your workout history as a CSV file that can be opened in Excel, Numbers, or Google Sheets.")
                .foregroundStyle(.secondary)

            Button("Export Workout History CSV") {
                csvDocument = CSVDocument(text: csvText())
                showCSVExporter = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
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
            
            Button("Export Full Backup JSON") {
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
            }
            .buttonStyle(.bordered)
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

            Button("Import Full Backup JSON") {
                showJSONImporter = true
            }
            .buttonStyle(.bordered)
            .fileImporter(
                isPresented: $showJSONImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importBackup(from: url)
                case .failure(let error):
                    print("Failed to import JSON backup: \(error)")
                }
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .navigationTitle("Backup & Export")
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

    private func importBackup(from url: URL) {
        do {
            let data = try Data(contentsOf: url)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let backup = try decoder.decode(AppBackup.self, from: data)

            logStore.replaceAll(with: backup.logs)
            templateStore.replaceAll(with: backup.templates)
            equipmentStore.replace(with: backup.equipment)
            settingsStore.replace(with: backup.settings)

            print("Backup imported successfully")
        } catch {
            print("Failed to import backup: \(error)")
        }
    }
}
