import SwiftUI

#if canImport(UIKit)
import UIKit

enum Keyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#endif

struct DismissKeyboardOnTap: ViewModifier {

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                Keyboard.dismiss()
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
