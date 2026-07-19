import SwiftUI

struct BigStepperControl: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let suffix: String?

    @State private var textValue = ""

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            TextField(title, text: $textValue)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(AppTheme.Typography.numeric(30))
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .onChange(of: textValue) {
                    updateValueWhileTyping()
                }
                .onChange(of: value) {
                    textValue = "\(value)"
                }
                .onAppear {
                    textValue = "\(value)"
                }

            HStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    value = max(range.lowerBound, value - step)
                    textValue = "\(value)"
                } label: {
                    Image(systemName: "minus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Decrease \(title.lowercased())")
                .accessibilityValue("\(value)\(suffix.map { " \($0)" } ?? "")")

                Button {
                    value = min(range.upperBound, value + step)
                    textValue = "\(value)"
                } label: {
                    Image(systemName: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Increase \(title.lowercased())")
                .accessibilityValue("\(value)\(suffix.map { " \($0)" } ?? "")")
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

        if let enteredValue = Int(textValue) {
            value = min(range.upperBound, max(range.lowerBound, enteredValue))
        }
    }

    private func restoreIfEmpty() {
        if textValue.isEmpty {
            textValue = "\(value)"
        }
    }
}
