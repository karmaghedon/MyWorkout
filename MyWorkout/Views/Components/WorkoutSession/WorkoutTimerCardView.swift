import SwiftUI

struct WorkoutTimerCardView: View {
    let elapsedTime: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("WORKOUT TIME")
                    .font(AppTheme.Typography.eyebrow)
                    .foregroundStyle(.secondary)

                Text(elapsedTime)
                    .font(AppTheme.Typography.numeric(28))
                    .monospacedDigit()
            }

            Spacer()

            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }
}
