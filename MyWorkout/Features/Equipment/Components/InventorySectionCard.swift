import SwiftUI

struct InventorySectionCard<Content: View>: View {
    let title: String
    private let content: () -> Content

    init(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.content = content
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SectionHeader(title: title)

                content()
            }
        }
    }
}
