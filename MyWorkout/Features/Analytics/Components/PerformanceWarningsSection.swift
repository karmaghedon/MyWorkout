import SwiftUI

struct PerformanceWarningsSection: View {
    let warnings: [ExercisePerformanceWarning]

    var body: some View {
        Section {
            if warnings.isEmpty {
                Text("No performance warnings")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(warnings) { warning in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(warning.exerciseName)
                            .font(.headline)

                        Text(warning.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            Label("Performance Warnings", systemImage: "exclamationmark.triangle.fill")
        }
    }
}

#Preview {
    List {
        PerformanceWarningsSection(warnings: [])
    }
}
