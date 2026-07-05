import SwiftUI

struct CurrentSetCardView: View {
    
    @Binding var weight: Int
    @Binding var reps: Int

    let weightRange: ClosedRange<Int>
    let weightStep: Int
    let weightUnit: String

    let repRange: ClosedRange<Int>

    let nextSetNumber: Int

    let onLogSet: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("CURRENT SET")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppTheme.Spacing.md) {
                BigStepperControl(
                    title: "Weight",
                    value: $weight,
                    range: weightRange,
                    step: weightStep,
                    suffix: weightUnit
                )

                BigStepperControl(
                    title: "Reps",
                    value: $reps,
                    range: weightRange,
                    step: 1,
                    suffix: nil
                )
            }

            Button(action: onLogSet) {
                Label("Log Set \(nextSetNumber)", systemImage: "checkmark.circle.fill")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.subtleFill)
        )
    }
}
