import SwiftUI

struct DoubleBigStepperControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let suffix: String?

    @State private var draftText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                TextField(title, text: $draftText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(AppTheme.Typography.numeric(30))
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                    .focused($isFocused)
                    .onChange(of: draftText) {
                        updateValueFromDraft()
                    }
                    .onChange(of: value) {
                        syncDraftFromValueIfNeeded()
                    }
                    .onChange(of: isFocused) { _, focused in
                        if focused {
                            draftText = formatWeight(value)
                        } else {
                            commitDraft()
                        }
                    }
                    .onAppear {
                        draftText = formatWeight(value)
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
                .accessibilityValue(accessibilityValue)

                Button {
                    increase()
                } label: {
                    Image(systemName: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Increase \(title.lowercased())")
                .accessibilityValue(accessibilityValue)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .onDisappear {
            commitDraft()
        }
    }

    private var accessibilityValue: String {
        "\(formatWeight(value))\(suffix.map { " \($0)" } ?? "")"
    }

    private func updateValueFromDraft() {
        guard isFocused else { return }
        guard !draftText.isEmpty else { return }

        if let enteredValue = Double(normalizedDraftText) {
            value = clamp(roundToOneDecimal(enteredValue))
        }
    }

    private func syncDraftFromValueIfNeeded() {
        guard !isFocused else { return }
        draftText = formatWeight(value)
    }

    private func commitDraft() {
        guard !draftText.isEmpty else {
            draftText = formatWeight(value)
            return
        }

        guard let enteredValue = Double(normalizedDraftText) else {
            draftText = formatWeight(value)
            return
        }

        value = clamp(roundToOneDecimal(enteredValue))
        draftText = formatWeight(value)
    }

    private func increase() {
        isFocused = false
        value = clamp(roundToOneDecimal(value + step))
        draftText = formatWeight(value)
    }

    private func decrease() {
        isFocused = false
        value = clamp(roundToOneDecimal(value - step))
        draftText = formatWeight(value)
    }

    private var normalizedDraftText: String {
        draftText.replacingOccurrences(of: ",", with: ".")
    }

    private func clamp(_ value: Double) -> Double {
        min(range.upperBound, max(range.lowerBound, value))
    }

    private func roundToOneDecimal(_ value: Double) -> Double {
        Rounding.toDecimalPlaces(value, 1)
    }
}
