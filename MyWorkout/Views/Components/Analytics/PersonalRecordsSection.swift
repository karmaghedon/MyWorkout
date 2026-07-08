import SwiftUI

struct PersonalRecordsSection: View {
    let personalRecords: [(exercise: String, weight: Double, reps: Int)]
    let settings: UserSettings

    var body: some View {
        Section {
            if personalRecords.isEmpty {
                Text("No PRs yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(personalRecords, id: \.exercise) { pr in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                            .accessibilityHidden(true)

                        Text(pr.exercise)

                        Spacer()

                        Text("\(formatWeight(settings.displayWeight(pr.weight))) \(settings.weightUnitLabel) × \(pr.reps)")
                            .bold()
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        "\(pr.exercise), personal record: \(formatWeight(settings.displayWeight(pr.weight))) \(settings.weightUnitLabel), \(pr.reps) reps"
                    )
                }
            }
        } header: {
            Label("Personal Records", systemImage: "trophy.fill")
        }
    }
}

#Preview {
    List {
        PersonalRecordsSection(
            personalRecords: [(exercise: "Bench Press", weight: 225, reps: 5)],
            settings: .defaults
        )
    }
}
