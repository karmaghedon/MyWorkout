import SwiftUI

struct PrimaryButton: View {
    let title: LocalizedStringKey
    let systemImage: String?
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    init(
        title: LocalizedStringKey,
        systemImage: String? = nil,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(AppTheme.onAccentFill)
                        .accessibilityHidden(true)
                } else {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .accessibilityHidden(true)
                    }

                    Text(title)
                }
            }
            .foregroundStyle(AppTheme.onAccentFill)
            .font(AppTheme.Typography.label)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.accent)
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
    }
}
