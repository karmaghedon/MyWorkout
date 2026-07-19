import SwiftUI

struct ValidatedNameField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        TextField(title, text: $text)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .font(AppTheme.Typography.label)
            .accessibilityLabel(title)
    }
}

// MARK: - Name Validation

extension String {
    var normalizedName: String {
        trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    var isValidName: Bool {
        !normalizedName.isEmpty
    }
}
