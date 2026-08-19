import SwiftUI

/// A titled group of `QuickActionRow` destinations in a single card —
/// the layout `DashboardView` originally built inline for its Manage/
/// Progress sections, extracted once a second screen (the Progress and
/// Profile tab hubs) needed the exact same shape.
struct QuickActionSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: AppTheme.Spacing.sm
        ) {
            SectionHeader(title: title)
                .padding(.horizontal)

            AppCard {
                VStack(spacing: 0) {
                    content()
                }
            }
            .padding(.horizontal)
        }
    }
}
