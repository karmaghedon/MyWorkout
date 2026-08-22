import SwiftUI
import UIKit

/// A `UITextField`-backed numeric field that always keeps the cursor
/// anchored at the end of the text. Plain SwiftUI `TextField` drops the
/// cursor wherever the user taps, which makes a short weight/rep number
/// fiddly to edit — a tap that lands mid-string puts new digits in the
/// middle instead of appending, and deleting the last digit requires
/// tapping exactly at the end first. Editing these fields is always
/// "replace the whole number," so the cursor is forced back to the end on
/// every tap/selection change rather than following the touch.
struct NumericPadTextField: UIViewRepresentable {
    @Binding var text: String
    var keyboardType: UIKeyboardType = .decimalPad
    var textAlignment: NSTextAlignment = .center
    var font: UIFont = .preferredFont(forTextStyle: .body)

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.textAlignment = textAlignment
        textField.font = font
        textField.text = text
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        guard uiView.text != text else { return }
        uiView.text = text
        moveCursorToEnd(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    private func moveCursorToEnd(_ textField: UITextField) {
        let end = textField.endOfDocument
        textField.selectedTextRange = textField.textRange(from: end, to: end)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        @objc func textChanged(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            snapToEnd(textField)
        }

        /// Fires on every tap/selection change, not just on focus gain —
        /// this is what stops a mid-editing tap from repositioning the
        /// cursor anywhere but the end. Guarded so it doesn't fight
        /// itself: setting `selectedTextRange` below fires this delegate
        /// method again, and the guard sees the selection is already
        /// collapsed at the end and returns without looping.
        func textFieldDidChangeSelection(_ textField: UITextField) {
            snapToEnd(textField)
        }

        private func snapToEnd(_ textField: UITextField) {
            let end = textField.endOfDocument

            if let selection = textField.selectedTextRange,
               selection.start == end,
               selection.end == end {
                return
            }

            textField.selectedTextRange = textField.textRange(from: end, to: end)
        }
    }
}
