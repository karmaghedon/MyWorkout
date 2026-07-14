import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var logStore: WorkoutLogStore
    @EnvironmentObject private var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var activeWorkoutStore: ActiveWorkoutStore

    @State private var navigationPath: [AppRoute] = []

    private var columns: [GridItem] {
        [GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: AppTheme.Spacing.xl
                ) {
                    Text("MyWorkout")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal)

                    errorBanners

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
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
    }

    // MARK: - Navigation

    @ViewBuilder
    private func destination(
        for route: AppRoute
    ) -> some View {
        switch route {
        case .startWorkout:
            StartWorkoutView()

        case .history:
            HistoryView()

        case .analytics:
            AnalyticsView()

        case .strengthTrends:
            StrengthTrendView()

        case .templates:
            TemplatesView()

        case .equipmentInventory:
            EquipmentInventoryView()

        case .settings:
            SettingsView()

        case .export:
            ExportView()

        case .activeWorkout:
            WorkoutSessionView()

        case let .workoutLogDetail(logID):
            if let log = logStore.logs.first(
                where: { $0.id == logID }
            ) {
                WorkoutLogDetailView(log: log)
            } else {
                missingDestinationView(
                    title: "Workout Not Found",
                    message: "This workout may have been deleted."
                )
            }

        case let .editTemplate(templateID):
            if let template = templateStore.templates.first(
                where: { $0.id == templateID }
            ) {
                TemplateEditorView(template: template)
                    .id(template.id)
            } else {
                missingDestinationView(
                    title: "Template Not Found",
                    message: "This workout template may have been deleted."
                )
            }

        case let .exerciseDetail(exerciseID):
            if let exercise = exerciseRegistry.exercise(
                id: exerciseID
            ) {
                ExerciseDetailView(exercise: exercise)
            } else {
                missingDestinationView(
                    title: "Exercise Not Found",
                    message: "This exercise is no longer available."
                )
            }
        }
    }

    private var exerciseRegistry: ExerciseRegistry {
        ExerciseRegistryFactory.make(
            templates: templateStore.templates,
            logs: logStore.logs
        )
    }

    private func missingDestinationView(
        title: String,
        message: String
    ) -> some View {
        AppEmptyStateView(
            title: LocalizedStringKey(title),
            message: LocalizedStringKey(message),
            systemImage: "exclamationmark.triangle"
        )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
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
            activeWorkoutStore
        ]
    }

    private var currentErrorMessages: [String] {
        errorReportingStores.compactMap(
            \.currentError
        )
    }

    private var errorBanners: some View {
        VStack(
            alignment: .leading,
            spacing: AppTheme.Spacing.sm
        ) {
            ForEach(
                Array(currentErrorMessages.enumerated()),
                id: \.offset
            ) { _, message in
                errorBanner(message)
            }
        }
    }

    private func errorBanner(
        _ message: String
    ) -> some View {
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
