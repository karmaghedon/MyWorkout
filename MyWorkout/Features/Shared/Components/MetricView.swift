import SwiftUI

/// A compact label-over-value stack for a single glanceable number,
/// without its own card surface — use inside a parent card that already
/// provides the background (e.g. a stat row). For a metric that needs its
/// own surface, use `MetricCard`.
struct MetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label.uppercased())
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.secondaryText)

            Text(value)
                .font(AppTheme.Typography.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
