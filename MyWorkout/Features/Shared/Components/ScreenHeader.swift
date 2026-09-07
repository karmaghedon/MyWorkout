import SwiftUI

/// A screen-level title, e.g. the top of a scrolling root screen that
/// isn't carried by `.navigationTitle`.
struct ScreenHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppTheme.Typography.heroTitle)
    }
}
