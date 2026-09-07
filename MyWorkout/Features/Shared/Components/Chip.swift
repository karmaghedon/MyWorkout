import SwiftUI

/// A compact capsule label — a set counter, a previous-performance value,
/// anything short enough to sit inline. For a status-colored severity
/// indicator use `ProgressBadge`; for a tag-style descriptor on its own
/// material use `InfoBadge`.
struct Chip: View {
    let text: String
    var font: Font = AppTheme.Typography.caption
    var backgroundColor: Color = AppTheme.subtleFill
    var foregroundColor: Color = AppTheme.secondaryText

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 6)
            .background(Capsule().fill(backgroundColor))
    }
}
