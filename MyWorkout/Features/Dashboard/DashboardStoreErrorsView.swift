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
                    .foregroundStyle(AppTheme.error)
                    .padding()
                    .background(AppTheme.error.opacity(0.12))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.Radius.control
                        )
                    )
                    .padding(.horizontal)
            }
        }
    }
}
