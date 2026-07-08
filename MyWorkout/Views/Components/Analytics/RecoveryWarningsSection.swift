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

                            Text(warning.severity.rawValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.orange.opacity(0.2))
                                .clipShape(Capsule())
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
}

#Preview {
    List {
        RecoveryWarningsSection(warnings: [])
    }
}
