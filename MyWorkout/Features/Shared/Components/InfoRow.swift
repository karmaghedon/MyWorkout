import SwiftUI

/// A label-and-value row — exercise detail facts, settings summaries,
/// anywhere a title/value pair needs consistent spacing and truncation.
struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)

            Spacer(minLength: AppTheme.Spacing.md)

            Text(value)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    List {
        InfoRow(title: "Equipment", value: "Barbell")
    }
}
