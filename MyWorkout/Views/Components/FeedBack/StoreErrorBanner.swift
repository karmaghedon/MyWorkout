import SwiftUI

struct StoreErrorBanner: View {
    let error: StoreError
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(error.operation.displayName) Error")
                    .font(AppTheme.Typography.label)

                Text(error.message)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
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
            .stroke(.orange.opacity(0.35))
        }
        .accessibilityElement(children: .combine)
    }
}
