import SwiftUI

/// A small, single-row timer bar pinned above the scrolling exercise list
/// (see `WorkoutSessionContentView`) — the full-width `WorkoutTimerCardView`
/// stays for anywhere that still wants a standalone card, but the session
/// screen itself now docks this bar under the nav bar instead.
struct CompactWorkoutTimerBar: View {
    let elapsedTime: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "timer")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)

            Text(elapsedTime)
                .font(AppTheme.Typography.numeric(17))

            Text("Workout Time")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.secondaryText)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: AppTheme.StrokeWidth.hairline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Workout time, \(elapsedTime)")
    }
}
