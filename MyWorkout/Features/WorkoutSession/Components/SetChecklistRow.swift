import SwiftUI

/// One row in the Checklist layout — used for both warm-up sets and
/// working sets, since visually they're identical: a checkbox, a
/// title/subtitle, and an optional plate chip. Reuses `Chip` rather than
/// inventing new chip styling.
struct SetChecklistRow: View {
    let title: String
    let subtitle: String?
    let plateText: String?
    let isComplete: Bool
    let isNext: Bool
    let onToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button {
                onToggle?()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(
                            isComplete
                                ? Color.clear
                                : (isNext ? AppTheme.accent : Color.primary.opacity(0.2)),
                            lineWidth: 2
                        )
                        .background(Circle().fill(isComplete ? AppTheme.success : Color.clear))

                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 26, height: 26)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(onToggle == nil)
            .accessibilityLabel(isComplete ? "Completed: \(title)" : "Mark complete: \(title)")

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.label)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Spacer(minLength: 0)

            if let plateText {
                Chip(
                    text: plateText,
                    font: AppTheme.Typography.caption,
                    backgroundColor: AppTheme.subtleFill,
                    foregroundColor: AppTheme.secondaryText
                )
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            (isNext && !isComplete)
                ? AnyView(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                        .fill(AppTheme.accentMuted)
                  )
                : AnyView(Color.clear)
        )
    }
}
