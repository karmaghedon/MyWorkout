import SwiftUI

/// A bordered, lower-emphasis counterpart to `PrimaryButton` — use for the
/// less important action in a pair (e.g. "Cancel" beside "Save").
struct SecondaryButton: View {
    let title: LocalizedStringKey
    let systemImage: String?
    let isEnabled: Bool
    let action: () -> Void

    init(
        title: LocalizedStringKey,
        systemImage: String? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }

                Text(title)
            }
            .font(AppTheme.Typography.label)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
        .tint(Color.primary)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}
