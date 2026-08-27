import SwiftUI

/// The "alive" moment of an active workout: a rest countdown that's
/// impossible to miss between sets, with a quiet progress ring so you can
/// tell how much rest is left without reading the number.
struct RestTimerBadge: View {
    let secondsRemaining: Int
    let totalSeconds: Int
    let onStop: () -> Void

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(secondsRemaining) / Double(totalSeconds)
    }

    private var timeText: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.2), lineWidth: AppTheme.StrokeWidth.ring)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: AppTheme.StrokeWidth.ring, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: AppTheme.Motion.linearContinuous), value: progress)

                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text("RESTING")
                    .font(AppTheme.Typography.eyebrow)
                    .foregroundStyle(.secondary)

                Text(timeText)
                    .font(AppTheme.Typography.numeric(22))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Resting, \(timeText) remaining")

            Spacer()

            IconButton(
                systemImage: "xmark.circle.fill",
                accessibilityLabel: "Stop rest timer",
                size: 22,
                action: onStop
            )
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.accentMuted)
        )
        .transition(AppTheme.Motion.cardTransition)
    }
}

extension RestTimerBadge {
    /// Stable scroll-anchor id for the badge itself, distinct from the
    /// exercise card's own id. The card can be much taller than the
    /// screen (warm-ups, several logged sets, notes), so scrolling to
    /// center the *card* doesn't put the badge — which can sit well down
    /// the card — anywhere near the center of the viewport. Scrolling to
    /// this id instead centers the badge exactly.
    static func scrollAnchorID(for exerciseID: UUID) -> String {
        "restTimerBadge_\(exerciseID.uuidString)"
    }
}
