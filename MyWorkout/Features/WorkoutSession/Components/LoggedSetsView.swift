import SwiftUI

struct LoggedSetsView: View {
    let sets: [LoggedSet]
        let displayWeight: (Double) -> Double
        let weightUnit: String
        let onDeleteSet: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("TODAY")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            ForEach(sets) { set in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)

                    Text("Set \(set.setNumber)")
                        .font(AppTheme.Typography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(formatWeight(displayWeight(set.weight))) \(weightUnit) × \(set.reps)")
                        .font(AppTheme.Typography.numeric(16))

                    IconButton(
                        systemImage: "xmark",
                        accessibilityLabel: "Delete set \(set.setNumber)",
                        size: 11,
                        weight: .bold
                    ) {
                        onDeleteSet(set.id)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }
}
