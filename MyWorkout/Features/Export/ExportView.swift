import SwiftUI

struct ExportView: View {
    var body: some View {
        Form {
            ExportActionsSection()
            ImportActionsSection()
        }
        .navigationTitle("Backup & Export")
    }
}
