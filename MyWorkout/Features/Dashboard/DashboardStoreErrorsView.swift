import SwiftUI

struct DashboardStoreErrorsView: View {
    let messages: [String]

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: AppTheme.Spacing.sm
        ) {
            ForEach(
                Array(messages.enumerated()),
                id: \.offset
            ) { _, message in
                Text(message)
                    .foregroundStyle(.red)
                    .padding()
                    .background(.red.opacity(0.12))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12
                        )
                    )
                    .padding(.horizontal)
            }
        }
    }
}
