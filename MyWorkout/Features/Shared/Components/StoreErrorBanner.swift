import SwiftUI

struct StoreErrorBanner: View {
    let error: StoreError
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.error)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(error.operation.displayName) Error")
                    .font(AppTheme.Typography.label)

                Text(error.message)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            IconButton(
                systemImage: "xmark",
                accessibilityLabel: "Dismiss error",
                size: 13,
                weight: .semibold,
                action: onDismiss
            )
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(
                cornerRadius: AppTheme.Radius.control,
                style: .continuous
            )
            .fill(AppTheme.cardBackground)
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppTheme.Radius.control,
                style: .continuous
            )
            .stroke(AppTheme.error.opacity(0.35), lineWidth: AppTheme.StrokeWidth.hairline)
        }
        .accessibilityElement(children: .combine)
    }
}
