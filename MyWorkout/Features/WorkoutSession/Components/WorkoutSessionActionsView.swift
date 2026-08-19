import SwiftUI

struct WorkoutSessionActionsView: View {
    let onFinish: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Button {
                onFinish()
            } label: {
                Text("Finish Workout")
                    .font(AppTheme.Typography.label)
                    .foregroundStyle(AppTheme.onAccentFill)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
            .padding(.top, AppTheme.Spacing.lg)

            Button(role: .destructive) {
                onCancel()
            } label: {
                Text("Cancel Workout")
                    .font(AppTheme.Typography.label)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
    }
}
