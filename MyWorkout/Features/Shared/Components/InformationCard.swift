import SwiftUI

/// A card presenting a title and a short supporting line — dashboard
/// tiles, informational callouts.
struct InformationCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AppTheme.Typography.cardTitle)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        }
    }
}
