import SwiftUI

/// A bordered button styled in `AppTheme.error` for a destructive, but not
/// yet irreversible, action (the confirmation itself belongs to the
/// caller — this button only signals intent).
struct DestructiveButton: View {
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
        Button(role: .destructive, action: action) {
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
        .tint(AppTheme.error)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}
