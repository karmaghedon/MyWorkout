import SwiftUI

struct WorkoutTimerCardView: View {
    let elapsedTime: String

    var body: some View {
        AppCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WORKOUT TIME")
                        .font(AppTheme.Typography.eyebrow)
                        .foregroundStyle(AppTheme.secondaryText)

                    Text(elapsedTime)
                        .font(AppTheme.Typography.numeric(28))
                }

                Spacer()

                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityHidden(true)
            }
        }
    }
}
