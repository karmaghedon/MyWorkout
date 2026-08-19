import SwiftUI

struct RecoveryWarningsSection: View {
    let warnings: [RecoveryWarning]

    var body: some View {
        Section {
            if warnings.isEmpty {
                Text("No recovery warnings")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(warnings) { warning in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(warning.title)
                                .font(.headline)

                            Spacer()

                            ProgressBadge(
                                text: warning.severity.rawValue,
                                color: severityColor(warning.severity)
                            )
                            .accessibilityLabel("Severity: \(warning.severity.rawValue)")
                        }

                        Text(warning.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Suggested action: \(warning.recommendation)")
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            Label("Recovery / Fatigue", systemImage: "heart.text.square.fill")
        }
    }

    private func severityColor(_ severity: WarningSeverity) -> Color {
        severity == .high ? AppTheme.error : AppTheme.warning
    }
}

#Preview {
    List {
        RecoveryWarningsSection(warnings: [])
    }
}
