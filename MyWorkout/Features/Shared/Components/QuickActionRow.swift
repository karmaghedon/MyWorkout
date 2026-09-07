import SwiftUI

/// A compact, chevron-terminated navigation row for a menu-style
/// destination — a settings-list idiom for content that isn't itself
/// workout data. Distinct from `WorkoutCard`, which is reserved for
/// workout-related items (templates, sessions, log entries) and has no
/// chevron since it's typically the only interactive element in its row.
///
/// Introduced in F3 (Home redesign) to replace a wall of full-height
/// `InformationCard` tiles with a scannable list for secondary
/// destinations (Analytics, Templates, Equipment, and similar) that
/// don't yet have a permanent tab of their own.
struct QuickActionRow: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.accentMuted)

                Image(systemName: systemImage)
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.label)
                    .foregroundStyle(Color.primary)

                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.tertiaryText)
                .accessibilityHidden(true)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
