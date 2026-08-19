import SwiftUI

/// The Profile tab root — per `NavigationArchitecture_F1.1.md` (F7), a
/// lightweight hub organizing Settings, Equipment, and Backup & Data
/// rather than defaulting straight into Settings.
struct ProfileHubView: View {
    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: AppTheme.Spacing.xl
            ) {
                ScreenHeader(title: "Profile")
                    .padding(.horizontal)

                QuickActionSection(title: "Preferences") {
                    quickActionLink(
                        systemImage: "gearshape.fill",
                        title: "Settings",
                        subtitle: "Units, timers, formulas",
                        route: .settings
                    )
                }

                QuickActionSection(title: "Manage") {
                    quickActionLink(
                        systemImage: "scalemass",
                        title: "Equipment",
                        subtitle: "Inventory & plates",
                        route: .equipmentInventory
                    )

                    Divider()

                    quickActionLink(
                        systemImage: "tray.and.arrow.up",
                        title: "Backup & Data",
                        subtitle: "CSV export, import & backup",
                        route: .export
                    )
                }
            }
            .padding(.bottom)
        }
    }

    private func quickActionLink(
        systemImage: String,
        title: String,
        subtitle: String,
        route: AppRoute
    ) -> some View {
        NavigationLink(value: route) {
            QuickActionRow(
                systemImage: systemImage,
                title: title,
                subtitle: subtitle
            )
        }
        .buttonStyle(.plain)
    }
}
