import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var logStore: WorkoutLogStore
    @EnvironmentObject private var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var activeWorkoutStore: ActiveWorkoutStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore

    /// Routes to the Workout tab, resuming an in-progress session when one
    /// exists. Owned by `AppShellView` since only it holds tab selection
    /// and per-tab navigation paths — Home just asks for the switch.
    let onStartWorkout: () -> Void

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: AppTheme.Spacing.xl
            ) {
                header
                    .padding(.horizontal)

                DashboardStoreErrorsView(
                    messages: currentErrorMessages
                )

                heroCard
                    .padding(.horizontal)

                DashboardStatsView()

                if !recentLogs.isEmpty {
                    recentActivitySection
                }

                dashboardSection(title: "Progress") {
                    quickActionLink(
                        systemImage: "chart.bar.fill",
                        title: "Analytics",
                        subtitle: "PRs, volume, trends",
                        route: .analytics
                    )

                    Divider()

                    quickActionLink(
                        systemImage: "chart.line.uptrend.xyaxis",
                        title: "Strength",
                        subtitle: "1RM progression",
                        route: .strengthTrends
                    )
                }

                dashboardSection(title: "Manage") {
                    quickActionLink(
                        systemImage: "list.bullet.rectangle",
                        title: "Templates",
                        subtitle: "Create & edit workout plans",
                        route: .templates
                    )

                    Divider()

                    quickActionLink(
                        systemImage: "scalemass",
                        title: "Equipment",
                        subtitle: "Inventory & plates",
                        route: .equipmentInventory
                    )

                    Divider()

                    quickActionLink(
                        systemImage: "figure.strengthtraining.functional",
                        title: "Custom Exercises",
                        subtitle: "Create and manage your own exercises",
                        route: .customExercises
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            ScreenHeader(title: greeting)

            Text(Date.now.formatted(date: .complete, time: .omitted))
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 0..<12:
            "Good morning"
        case 12..<17:
            "Good afternoon"
        default:
            "Good evening"
        }
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroCard: some View {
        if activeWorkoutStore.hasActiveWorkout {
            activeWorkoutHero
        } else {
            startWorkoutHero
        }
    }

    private var activeWorkoutHero: some View {
        AppCard(backgroundColor: AppTheme.accentMuted) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workout in progress")
                            .font(AppTheme.Typography.eyebrow)
                            .foregroundStyle(AppTheme.secondaryText)

                        Text(activeWorkoutStore.activeWorkout?.name ?? "Active Workout")
                            .font(AppTheme.Typography.cardTitle)
                    }

                    Spacer(minLength: AppTheme.Spacing.sm)

                    Text(activeWorkoutStore.formattedElapsedTime)
                        .font(AppTheme.Typography.numeric(22))
                        .accessibilityLabel("Elapsed time \(activeWorkoutStore.formattedElapsedTime)")
                }

                PrimaryButton(
                    title: "Resume Workout",
                    systemImage: "play.fill",
                    action: onStartWorkout
                )
            }
        }
    }

    private var startWorkoutHero: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ready to train?")
                        .font(AppTheme.Typography.cardTitle)

                    Text("Start a workout from one of your templates.")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                PrimaryButton(
                    title: "Start Workout",
                    systemImage: "figure.strengthtraining.traditional",
                    action: onStartWorkout
                )
            }
        }
    }

    // MARK: - Recent Activity

    private var recentLogs: [WorkoutLog] {
        Array(logStore.logs.prefix(3))
    }

    private var recentActivitySection: some View {
        VStack(
            alignment: .leading,
            spacing: AppTheme.Spacing.sm
        ) {
            SectionHeader(title: "Recent Activity")
                .padding(.horizontal)

            AppCard {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(
                        Array(recentLogs.enumerated()),
                        id: \.element.id
                    ) { index, log in
                        NavigationLink(value: AppRoute.workoutLogDetail(log.id)) {
                            WorkoutCard(
                                systemImage: "checkmark.seal.fill",
                                title: log.workoutName
                            ) {
                                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        .buttonStyle(.plain)

                        if index < recentLogs.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Dashboard Sections

    private func dashboardSection<Content: View>(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: AppTheme.Spacing.sm
        ) {
            SectionHeader(title: title)
                .padding(.horizontal)

            AppCard {
                VStack(spacing: 0) {
                    content()
                }
            }
            .padding(.horizontal)
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
