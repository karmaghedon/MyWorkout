import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var logStore: WorkoutLogStore
    @EnvironmentObject private var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var activeWorkoutStore: ActiveWorkoutStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore
    @EnvironmentObject private var analyticsCache: AnalyticsCache
    @EnvironmentObject private var bodyMeasurementLogStore: BodyMeasurementLogStore
    @EnvironmentObject private var macroGoalStore: MacroGoalStore
    @EnvironmentObject private var dailyNutritionLogStore: DailyNutritionLogStore

    /// Routes to the Workout tab, resuming an in-progress session when one
    /// exists. Owned by `AppShellView` since only it holds tab selection
    /// and per-tab navigation paths — Home just asks for the switch.
    let onStartWorkout: () -> Void

    var body: some View {
        TourScrollView(tab: .home) {
            VStack(
                alignment: .leading,
                spacing: AppTheme.Spacing.xl
            ) {
                header
                    .padding(.horizontal)

                DashboardStoreErrorsView(
                    messages: currentErrorMessages
                )

                needsAttentionBanner

                WeeklyMeasurementsReminderBanner()

                WeeklySummaryCard()
                    .tourAnchor("home-week-summary")

                bodyMetricsQuickActionsSection
                    .tourAnchor("home-log-weight")

                heroCard
                    .padding(.horizontal)
                    .tourAnchor("home-hero")

                todaysNutritionSection
                    .tourAnchor("home-nutrition")
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

    /// Shows the single most-due template directly in the hero, rather
    /// than as a separate "Next Up" section below it — one primary call
    /// to action instead of two competing ones. Falls back to the
    /// generic prompt when there's no template yet to suggest.
    @ViewBuilder
    private var startWorkoutHero: some View {
        if let template = suggestedNextTemplate {
            AppCard {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Up")
                            .font(AppTheme.Typography.eyebrow)
                            .foregroundStyle(AppTheme.secondaryText)

                        Text(template.name)
                            .font(AppTheme.Typography.cardTitle)

                        Text(nextWorkoutSubtitle(for: template))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    PrimaryButton(
                        title: "Start Workout",
                        systemImage: "figure.strengthtraining.traditional"
                    ) {
                        startSuggestedWorkout(template)
                    }

                    Button("Choose a different workout", action: onStartWorkout)
                        .font(AppTheme.Typography.caption)
                }
            }
        } else {
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
    }

    // MARK: - Next Workout

    /// The template that's most "due" — least recently performed, with
    /// never-performed templates treated as the most overdue of all.
    private var suggestedNextTemplate: WorkoutTemplate? {
        templateStore.templates.min {
            (lastPerformedDate(for: $0) ?? .distantPast)
                < (lastPerformedDate(for: $1) ?? .distantPast)
        }
    }

    private func lastPerformedDate(for template: WorkoutTemplate) -> Date? {
        logStore.logs
            .filter { $0.workoutName == template.name }
            .map(\.date)
            .max()
    }

    private func nextWorkoutSubtitle(for template: WorkoutTemplate) -> String {
        guard let lastDate = lastPerformedDate(for: template) else {
            return "Not started yet"
        }

        return "Last done \(lastDate.formatted(.relative(presentation: .named)))"
    }

    private func startSuggestedWorkout(_ template: WorkoutTemplate) {
        let workout = Workout(
            name: template.name,
            exercises: template.exercises
        )

        if case .started = activeWorkoutStore.start(workout) {
            onStartWorkout()
        }
    }

    // MARK: - Today's Nutrition

    private var todaysNutritionSection: some View {
        TodayNutritionCard()
    }

    // MARK: - Body Metrics

    /// "Log Weight" only — matching the same NavigationLink-wrapped
    /// `AppCard` pattern used elsewhere on this screen. No "Log
    /// Nutrition" card here: `TodayNutritionCard`
    /// already links to the same `AppRoute.logNutrition` screen, so a
    /// second entry point next to this one was pure duplication.
    private var bodyMetricsQuickActionsSection: some View {
        NavigationLink(value: AppRoute.logWeight) {
            AppCard {
                WorkoutCard(
                    systemImage: "scalemass.fill",
                    title: "Log Weight"
                ) {
                    Text("Weight, body fat %, waist, and neck")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    // MARK: - Needs Attention

    /// A single entry point into Analytics for anything that needs a
    /// look — recovery warnings and performance warnings both already
    /// get their own full sections there (`RecoveryWarningsSection`,
    /// `PerformanceWarningsSection`), so Home only needs a count and a
    /// link, not a duplicate rendering of the warnings themselves.
    private var totalAlerts: Int {
        analyticsCache.recoveryWarnings.count + analyticsCache.performanceWarnings.count
    }

    @ViewBuilder
    private var needsAttentionBanner: some View {
        if totalAlerts > 0 {
            NavigationLink(value: AppRoute.analytics) {
                AppCard {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Label(
                            "\(totalAlerts) item\(totalAlerts == 1 ? "" : "s") need attention",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(AppTheme.warning)
                        .font(AppTheme.Typography.label)

                        Spacer(minLength: AppTheme.Spacing.sm)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
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
            customExerciseStore,
            bodyMeasurementLogStore,
            macroGoalStore,
            dailyNutritionLogStore
        ]
    }

    private var currentErrorMessages: [String] {
        errorReportingStores.compactMap(
            \.currentError
        )
    }
}
