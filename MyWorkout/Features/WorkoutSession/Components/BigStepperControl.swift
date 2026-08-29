import SwiftUI
import UIKit

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

            // `NumericPadTextField` (not a plain SwiftUI `TextField`)
            // because editing here needs to be "replace the whole
            // number": a plain `TextField` lands the cursor wherever a
            // tap landed and lets new digits append, which turned typing
            // "7" over an existing "6" into "67". `NumericPadTextField`
            // already solves exactly this for other numeric fields in
            // this app by selecting the existing value on focus.
            NumericPadTextField(
                text: $textValue,
                keyboardType: .numberPad,
                textAlignment: .center,
                font: numericFont
            )
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
                .frame(minHeight: 44)
                .contentShape(Rectangle())
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
                .frame(minHeight: 44)
                .contentShape(Rectangle())
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

    /// Matches `AppTheme.Typography.numeric(30)` as closely as UIKit
    /// allows — `NumericPadTextField` is a `UIViewRepresentable`, so a
    /// SwiftUI `.font()` modifier can't reach its underlying `UITextField`.
    private var numericFont: UIFont {
        let base = UIFont.systemFont(ofSize: 30, weight: .bold)
        guard let roundedDescriptor = base.fontDescriptor.withDesign(.rounded) else {
            return base
        }
        return UIFont(descriptor: roundedDescriptor, size: 30)
    }
}
