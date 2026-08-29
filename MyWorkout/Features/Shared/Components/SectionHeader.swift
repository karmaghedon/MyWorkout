import SwiftUI

/// A section-level title — groups of dashboard links, card groupings.
/// Centralizing this means the section-title treatment (currently just
/// `AppTheme.Typography.sectionTitle`) can evolve in one place.
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppTheme.Typography.sectionTitle)
    }
}
