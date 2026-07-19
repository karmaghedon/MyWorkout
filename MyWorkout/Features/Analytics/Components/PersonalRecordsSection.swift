import SwiftUI

struct PersonalRecordsSection: View {
    let personalRecords: [PersonalRecord]
    let settings: UserSettings

    var body: some View {
        Section {
            if personalRecords.isEmpty {
                Text("No PRs yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(personalRecords) { record in
                    HStack(
                        spacing: AppTheme.Spacing.sm
                    ) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                            .accessibilityHidden(true)

                        Text(record.exerciseName)

                        Spacer()

                        Text(
                            formattedRecord(record)
                        )
                        .bold()
                    }
                    .accessibilityElement(
                        children: .ignore
                    )
                    .accessibilityLabel(
                        accessibilityDescription(
                            for: record
                        )
                    )
                }
            }
        } header: {
            Label(
                "Personal Records",
                systemImage: "trophy.fill"
            )
        }
    }

    private func formattedRecord(
        _ record: PersonalRecord
    ) -> String {
        let displayedWeight = settings.displayWeight(
            record.weightPounds
        )

        return
            "\(formatWeight(displayedWeight)) "
            + "\(settings.weightUnitLabel) "
            + "× \(record.reps)"
    }

    private func accessibilityDescription(
        for record: PersonalRecord
    ) -> String {
        let displayedWeight = settings.displayWeight(
            record.weightPounds
        )

        return
            "\(record.exerciseName), personal record: "
            + "\(formatWeight(displayedWeight)) "
            + "\(settings.weightUnitLabel), "
            + "\(record.reps) reps"
    }
}

#Preview {
    List {
        PersonalRecordsSection(
            personalRecords: [
                PersonalRecord(
                    exerciseID: nil,
                    exerciseName: "Bench Press",
                    weightPounds: 225,
                    reps: 5
                )
            ],
            settings: .defaults
        )
    }
}
