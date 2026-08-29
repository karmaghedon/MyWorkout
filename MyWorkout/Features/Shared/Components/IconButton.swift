import SwiftUI

/// A single icon rendered as a tappable control with a full 44×44 minimum
/// touch target, even when the icon itself is drawn smaller. Use for
/// dismiss, stop, and other icon-only actions instead of a bare
/// `Image` wrapped in `.buttonStyle(.plain)`.
struct IconButton: View {
    let systemImage: String
    let accessibilityLabel: LocalizedStringKey
    var size: CGFloat = 22
    var weight: Font.Weight = .regular
    var color: Color = AppTheme.secondaryText
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size, weight: weight))
                .foregroundStyle(color)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
