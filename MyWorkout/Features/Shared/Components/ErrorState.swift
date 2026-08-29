import SwiftUI

/// A full-screen failure state — icon, title, and message tinted with
/// `AppTheme.error`. For a small, dismissible inline failure banner
/// alongside other content, use `StoreErrorBanner` instead.
struct ErrorState: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var systemImage: String = "exclamationmark.triangle.fill"

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.error)
                .accessibilityHidden(true)

            Text(title)
                .font(AppTheme.Typography.cardTitle)

            Text(message)
                .font(AppTheme.Typography.label)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .multilineTextAlignment(.center)
        .padding()
        .accessibilityElement(children: .combine)
    }
}
