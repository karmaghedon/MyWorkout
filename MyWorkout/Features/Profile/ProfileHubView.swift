import SwiftUI

/// The Profile tab root — per `NavigationArchitecture_F1.1.md` (F7), a
/// lightweight hub organizing Settings, Equipment, and Backup & Data
/// rather than defaulting straight into Settings.
struct ProfileHubView: View {
    @EnvironmentObject private var activeWorkoutStore: ActiveWorkoutStore
    @EnvironmentObject private var tourCoordinator: TourCoordinator

    var body: some View {
        TourScrollView(tab: .profile) {
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
                .tourAnchor("profile-settings")

                QuickActionSection(title: "Health & Nutrition") {
                    quickActionLink(
                        systemImage: "target",
                        title: "Macro Goals",
                        subtitle: "Calorie & macro targets",
                        route: .macroGoals
                    )
                }
                .tourAnchor("profile-macro-goals")

                QuickActionSection(title: "Manage") {
                    quickActionLink(
                        systemImage: "scalemass",
                        title: "Equipment",
                        subtitle: "Inventory & plates",
                        route: .equipmentInventory
                    )
                    .tourAnchor("profile-equipment")

                    Divider()

                    quickActionLink(
                        systemImage: "tray.and.arrow.up",
                        title: "Backup & Data",
                        subtitle: "CSV export, import & backup",
                        route: .export
                    )
                    .tourAnchor("profile-backup")
                }

                QuickActionSection(title: "Help") {
                    Button {
                        tourCoordinator.start()
                    } label: {
                        QuickActionRow(
                            systemImage: "sparkles",
                            title: "Take the Tour",
                            subtitle: activeWorkoutStore.hasActiveWorkout
                                ? "Finish or cancel your active workout first"
                                : "A guided walkthrough of what the app can do"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(activeWorkoutStore.hasActiveWorkout)
                }

                QuickActionSection(title: "About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        QuickActionRow(
                            systemImage: "info.circle.fill",
                            title: "About MyWorkout",
                            subtitle: "Version, credits & app info"
                        )
                    }
                    .buttonStyle(.plain)
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
