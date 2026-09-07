import SwiftUI

/// A centered spinner with an optional caption — the counterpart to
/// `AppEmptyStateView` and `ErrorState` for a screen that's still
/// fetching its content.
struct LoadingState: View {
    var message: LocalizedStringKey?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ProgressView()

            if let message {
                Text(message)
                    .font(AppTheme.Typography.label)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .multilineTextAlignment(.center)
        .padding()
        .accessibilityElement(children: .combine)
    }
}
