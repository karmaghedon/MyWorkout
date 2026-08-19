import SwiftUI

/// An icon-badge row for a workout-related item — a template, a past
/// session, a log entry. Pass whatever detail line(s) fit the context as
/// `subtitle`.
struct WorkoutCard<Subtitle: View>: View {
    let systemImage: String
    let title: String
    @ViewBuilder let subtitle: () -> Subtitle

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.accentMuted)

                Image(systemName: systemImage)
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                subtitle()
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
