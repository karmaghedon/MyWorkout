import SwiftUI

struct AppTabLabel: View {
    let tab: AppTab

    var body: some View {
        Label(
            tab.title,
            systemImage: tab.systemImage
        )
        .accessibilityLabel(tab.accessibilityLabel)
    }
}
