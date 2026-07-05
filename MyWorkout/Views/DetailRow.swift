import SwiftUI

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)

            Spacer(minLength: AppTheme.Spacing.md)

            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    List {
        DetailRow(title: "Equipment", value: "Barbell")
    }
}
