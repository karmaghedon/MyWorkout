import SwiftUI

/// A single glanceable number in its own card — a strength estimate, a
/// personal record, any value that deserves more visual weight than an
/// inline stat.
struct MetricCard: View {
    let label: String
    let value: String
    var backgroundColor: Color = AppTheme.accentMuted

    var body: some View {
        AppCard(backgroundColor: backgroundColor, padding: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.secondaryText)

                Text(value)
                    .font(AppTheme.Typography.numeric(34))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
