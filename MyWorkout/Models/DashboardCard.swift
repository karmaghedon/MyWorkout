import SwiftUI

struct DashboardCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .bold()

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .frame(width: 240, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.gray.opacity(0.12))
        )
    }
}
