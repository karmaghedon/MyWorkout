import SwiftUI

/// A circular, elevated icon button anchored over content — the one
/// button in the library that reaches for `AppTheme.Elevation`, since it
/// must visually float above whatever it's layered on.
struct FloatingActionButton: View {
    let systemImage: String
    let accessibilityLabel: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.onAccentFill)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AppTheme.accent))
                .appShadow(AppTheme.Elevation.cardShadow)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
