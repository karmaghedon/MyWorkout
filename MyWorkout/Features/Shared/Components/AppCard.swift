import SwiftUI

/// The base card surface — standard padding, background, and corner
/// radius wrapped around arbitrary content. `WorkoutCard`, `MetricCard`,
/// and `InformationCard` are specific shapes built for common content;
/// reach for `AppCard` directly when none of them fit.
struct AppCard<Content: View>: View {
    var backgroundColor: Color = AppTheme.cardBackground
    var padding: CGFloat = AppTheme.Spacing.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                    .fill(backgroundColor)
            )
    }
}
