import SwiftUI

/// A card's title row, with room for a trailing accessory (a chip, a
/// button) baseline-aligned beside it.
struct CardHeader<Accessory: View>: View {
    let title: String
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTheme.Typography.cardTitle)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)

            Spacer(minLength: AppTheme.Spacing.md)

            accessory()
        }
    }
}

extension CardHeader where Accessory == EmptyView {
    init(title: String) {
        self.title = title
        self.accessory = { EmptyView() }
    }
}
