import SwiftUI

struct DoubleBigStepperControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let suffix: String?

    @State private var textValue = ""

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                TextField(title, text: $textValue)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(AppTheme.Typography.numeric(30))
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                    .onChange(of: textValue) {
                        updateValueWhileTyping()
                    }
                    .onChange(of: value) {
                        textValue = formatWeight(value)
                    }
                    .onAppear {
                        textValue = formatWeight(value)
                    }

                if let suffix {
                    Text(suffix)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    decrease()
                } label: {
                    Image(systemName: "minus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Decrease \(title.lowercased())")
                .accessibilityValue("\(formatWeight(value))\(suffix.map { " \($0)" } ?? "")")

                Button {
                    increase()
                } label: {
                    Image(systemName: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Increase \(title.lowercased())")
                .accessibilityValue("\(formatWeight(value))\(suffix.map { " \($0)" } ?? "")")
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .onDisappear {
            restoreIfEmpty()
        }
    }

    private func updateValueWhileTyping() {
        guard !textValue.isEmpty else { return }

        if let enteredValue = Double(textValue) {
            value = clamp(roundToOneDecimal(enteredValue))
        }
    }

    private func increase() {
        value = clamp(roundToOneDecimal(value + step))
        textValue = formatWeight(value)
    }

    private func decrease() {
        value = clamp(roundToOneDecimal(value - step))
        textValue = formatWeight(value)
    }

    private func restoreIfEmpty() {
        if textValue.isEmpty {
            textValue = formatWeight(value)
        }
    }

    private func clamp(_ value: Double) -> Double {
        min(range.upperBound, max(range.lowerBound, value))
    }

    private func roundToOneDecimal(_ value: Double) -> Double {
        Rounding.toDecimalPlaces(value, 1)
    }
}
