import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var logStore: WorkoutLogStore
    @EnvironmentObject private var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var activeWorkoutStore: ActiveWorkoutStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore

    private var columns: [GridItem] {
        [GridItem(.flexible())]
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: AppTheme.Spacing.xl
            ) {
                Text("MyWorkout")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)

                DashboardStoreErrorsView(
                    messages: currentErrorMessages
                )

                DashboardStatsView()

                dashboardSection(title: "Train") {
                    dashboardLink(
                        title: "Start Workout",
                        subtitle: "Begin training session",
                        route: .startWorkout
                    )

                    dashboardLink(
                        title: "History",
                        subtitle: "View previous workouts",
                        route: .history
                    )
                }

                dashboardSection(title: "Progress") {
                    dashboardLink(
                        title: "Analytics",
                        subtitle: "PRs, volume, trends",
                        route: .analytics
                    )

                    dashboardLink(
                        title: "Strength",
                        subtitle: "1RM progression",
                        route: .strengthTrends
                    )
                }

                dashboardSection(title: "Manage") {
                    dashboardLink(
                        title: "Templates",
                        subtitle: "Create & edit workout plans",
                        route: .templates
                    )

                    dashboardLink(
                        title: "Equipment",
                        subtitle: "Inventory & plates",
                        route: .equipmentInventory
                    )

                    dashboardLink(
                        title: "Custom Exercises",
                        subtitle: "Create and manage your own exercises",
                        route: .customExercises
                    )
                }

                dashboardSection(title: "Settings") {
                    dashboardLink(
                        title: "Settings",
                        subtitle: "Units, timers, formulas",
                        route: .settings
                    )

                    dashboardLink(
                        title: "Export",
                        subtitle: "CSV backup & reports",
                        route: .export
                    )
                }
            }
            .padding(.bottom)
        }
    }

    // MARK: - Dashboard Sections

    private func dashboardSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: AppTheme.Spacing.sm
        ) {
            Text(title)
                .font(AppTheme.Typography.sectionTitle)
                .padding(.horizontal)

            LazyVGrid(
                columns: columns,
                spacing: AppTheme.Spacing.lg
            ) {
                content()
            }
            .padding(.horizontal)
        }
    }

    private func dashboardLink(
        title: String,
        subtitle: String,
        route: AppRoute
    ) -> some View {
        NavigationLink(value: route) {
            DashboardCard(
                title: title,
                subtitle: subtitle
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error Reporting

    private var errorReportingStores: [
        any ErrorReportingStore
    ] {
        [
            logStore,
            templateStore,
            equipmentStore,
            settingsStore,
            activeWorkoutStore,
            customExerciseStore
        ]
    }

    private var currentErrorMessages: [String] {
        errorReportingStores.compactMap(
            \.currentError
        )
    }
}
