import SwiftUI

struct ExportView: View {
    var body: some View {
        Form {
            ExportActionsSection()
            ImportActionsSection()
            HistoricalDataImportSection()
        }
        .navigationTitle("Backup & Export")
    }
}
