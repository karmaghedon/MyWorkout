import SwiftUI

struct LoggedSetsView: View {
    let sets: [LoggedSet]
        let displayWeight: (Int) -> Int
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

                    Text("\(displayWeight(set.weight)) \(weightUnit) × \(set.reps)")
                        .font(AppTheme.Typography.numeric(16))

                    Button {
                        onDeleteSet(set.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete set \(set.setNumber)")
                }
                .padding(.vertical, 6)
            }
        }
    }
}
