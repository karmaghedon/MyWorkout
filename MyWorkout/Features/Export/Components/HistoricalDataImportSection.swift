import SwiftUI

/// Temporary, one-time fixup trigger for `HistoricalDataFixup` — remove
/// this file (and its wiring in `ExportView`) once the fixup has run
/// successfully. Deletes and rewrites specific real HealthKit samples,
/// so it's confirmed before running.
struct HistoricalDataImportSection: View {
    @EnvironmentObject private var bodyMeasurementLogStore: BodyMeasurementLogStore

    @State private var showConfirmation = false
    @State private var isRunning = false
    @State private var resultMessage: String?
    @State private var showResult = false

    var body: some View {
        Section {
            Button {
                showConfirmation = true
            } label: {
                Label("Fix Aug 24/31 Historical Data (One-Time)", systemImage: "wrench.and.screwdriver")
            }
            .disabled(isRunning)
        } footer: {
            Text("Deletes the incorrect Aug 24 and Aug 31 entries from the last import and re-adds a corrected Aug 24 week only. Run this once.")
        }
        .confirmationDialog(
            "Fix Historical Data?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Fix It", role: .destructive) {
                runFixup()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes specific weight/waist samples from Apple Health and re-adds a corrected Aug 24 week. Aug 31 is removed entirely. This can't be easily undone.")
        }
        .alert(
            "Fixup Complete",
            isPresented: $showResult,
            presenting: resultMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func runFixup() {
        isRunning = true

        Task {
            defer { isRunning = false }

            let result = await HistoricalDataFixup.run(bodyMeasurementLogStore: bodyMeasurementLogStore)

            var message = "Deleted \(result.deletedWeightSamples) weight, \(result.deletedWaistSamples) waist, \(result.deletedNeckLogs) neck entries. Re-imported \(result.reimportedWeeks) week."

            if !result.errors.isEmpty {
                message += " Errors: \(result.errors.joined(separator: "; "))"
            }

            resultMessage = message
            showResult = true
        }
    }
}
