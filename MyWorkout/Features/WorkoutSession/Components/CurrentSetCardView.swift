import SwiftUI

struct CurrentSetCardView: View {

    @Binding var weight: Double
    @Binding var reps: Int

    let weightRange: ClosedRange<Double>
    let weightStep: Double
    let weightUnit: String

    let repRange: ClosedRange<Int>

    let nextSetNumber: Int

    /// False when a superset partner still needs to catch up this round —
    /// see `WorkoutSessionEngine.canLogNextSet`.
    var canLogSet: Bool = true
    var waitingOnExerciseName: String? = nil

    let onLogSet: () -> Void

    var body: some View {
        AppCard(backgroundColor: AppTheme.subtleFill, padding: AppTheme.Spacing.md) {
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("CURRENT SET")
                    .font(AppTheme.Typography.eyebrow)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: AppTheme.Spacing.md) {
                    DoubleBigStepperControl(
                        title: "Weight",
                        value: $weight,
                        range: weightRange,
                        step: weightStep,
                        suffix: weightUnit
                    )

                    BigStepperControl(
                        title: "Reps",
                        value: $reps,
                        range: repRange,
                        step: 1,
                        suffix: nil
                    )
                }

                Button {
                    Keyboard.dismiss()
                    onLogSet()
                } label: {
                    Label("Log Set \(nextSetNumber)", systemImage: "checkmark.circle.fill")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.onAccentFill)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.large)
                .disabled(!canLogSet)

                if !canLogSet, let waitingOnExerciseName {
                    Label(
                        "Do \(waitingOnExerciseName)'s set first",
                        systemImage: "arrow.right.circle"
                    )
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}
