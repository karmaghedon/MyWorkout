import SwiftUI

/// A capsule that carries a status color — a warning severity, a
/// pass/fail state. The color communicates the status; `text` is the
/// human-readable label alongside it.
struct ProgressBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppTheme.Typography.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
    }
}
