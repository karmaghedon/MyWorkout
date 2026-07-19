import SwiftUI

struct InfoBadge: View {
    let text: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
            }

            Text(text)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        InfoBadge(text: "Chest")
        InfoBadge(text: "Barbell", systemImage: "dumbbell")
        InfoBadge(text: "Compound")
    }
    .padding()
}
