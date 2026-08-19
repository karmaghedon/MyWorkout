import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var logStore: WorkoutLogStore
    @EnvironmentObject private var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var activeWorkoutStore: ActiveWorkoutStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore
    @EnvironmentObject private var analyticsCache: AnalyticsCache

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

                nextWorkoutSection

                todaysProgressSection

                prHighlightsSection

                weeklySummarySection

                recoverySection

                DashboardStatsView()

                if !recentLogs.isEmpty {
                    recentActivitySection
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

    @ViewBuilder
    private var nextWorkoutSection: some View {
        if !activeWorkoutStore.hasActiveWorkout,
           let template = suggestedNextTemplate {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                SectionHeader(title: "Next Up")
                    .padding(.horizontal)

                AppCard {
                    HStack(spacing: AppTheme.Spacing.md) {
                        WorkoutCard(
                            systemImage: "figure.strengthtraining.traditional",
                            title: template.name
                        ) {
                            Text(nextWorkoutSubtitle(for: template))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }

                        IconButton(
                            systemImage: "play.fill",
                            accessibilityLabel: "Start \(template.name)",
                            color: AppTheme.accent
                        ) {
                            startSuggestedWorkout(template)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Today's Progress

    private var todaysLogs: [WorkoutLog] {
        logStore.logs.filter {
            Calendar.current.isDateInToday($0.date)
        }
    }

    private var activeWorkoutStartedToday: Bool {
        guard let startedAt = activeWorkoutStore.startedAt else {
            return false
        }

        return Calendar.current.isDateInToday(startedAt)
    }

    private var workoutsToday: Int {
        todaysLogs.count + (activeWorkoutStartedToday ? 1 : 0)
    }

    private var setsToday: Int {
        let completedSets = todaysLogs.reduce(0) { total, log in
            total + log.completedExercises.reduce(0) { $0 + $1.sets.count }
        }

        let activeSets = activeWorkoutStartedToday
            ? activeWorkoutStore.exerciseStates.values.reduce(0) { $0 + $1.loggedSets.count }
            : 0

        return completedSets + activeSets
    }

    private var todaysProgressSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SectionHeader(title: "Today")

                HStack(spacing: AppTheme.Spacing.md) {
                    MetricView(label: "Workouts", value: "\(workoutsToday)")
                    MetricView(label: "Sets", value: "\(setsToday)")
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - PR Highlights

    /// Current all-time personal records that were set by a set logged
    /// *today* — i.e. genuinely new, not just the standing best. Compares
    /// each all-time record against today's logged sets for the same
    /// exercise rather than requiring a date on `PersonalRecord` itself.
    private var newPersonalRecordsToday: [PersonalRecord] {
        let todaysSets: [(key: String, set: LoggedSet)] = todaysLogs.flatMap { log in
            log.completedExercises.flatMap { exercise -> [(key: String, set: LoggedSet)] in
                let key = exercise.exerciseID?.uuidString ?? exercise.exerciseName
                return exercise.sets.map { (key, $0) }
            }
        }

        return analyticsCache.personalRecords.filter { record in
            let recordKey = record.exerciseID?.uuidString ?? record.exerciseName

            return todaysSets.contains {
                $0.key == recordKey
                    && $0.set.weight == record.weightPounds
                    && $0.set.reps == record.reps
            }
        }
    }

    @ViewBuilder
    private var prHighlightsSection: some View {
        if !newPersonalRecordsToday.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                SectionHeader(title: "New Personal Records")
                    .padding(.horizontal)

                AppCard(backgroundColor: AppTheme.accentMuted) {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(
                            Array(newPersonalRecordsToday.enumerated()),
                            id: \.element.id
                        ) { index, record in
                            HStack(spacing: AppTheme.Spacing.md) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.exerciseName)
                                        .font(AppTheme.Typography.cardTitle)

                                    Text(
                                        "\(formatWeight(settingsStore.settings.displayWeight(record.weightPounds))) "
                                        + "\(settingsStore.settings.weightUnitLabel) × \(record.reps)"
                                    )
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                                }

                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .combine)

                            if index < newPersonalRecordsToday.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Weekly Summary

    private var currentWeekInterval: DateInterval? {
        Calendar.current.dateInterval(of: .weekOfYear, for: .now)
    }

    private var weekDays: [Date] {
        guard let interval = currentWeekInterval else {
            return []
        }

        let calendar = Calendar.current
        var days: [Date] = []
        var day = interval.start

        while day < interval.end {
            days.append(day)

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                break
            }

            day = nextDay
        }

        return days
    }

    private var thisWeeksLogs: [WorkoutLog] {
        guard let interval = currentWeekInterval else {
            return []
        }

        return logStore.logs.filter {
            interval.contains($0.date)
        }
    }

    private var activeWorkoutStartedThisWeek: Bool {
        guard let startedAt = activeWorkoutStore.startedAt,
              let interval = currentWeekInterval else {
            return false
        }

        return interval.contains(startedAt)
    }

    private var workoutsThisWeek: Int {
        thisWeeksLogs.count + (activeWorkoutStartedThisWeek ? 1 : 0)
    }

    private var setsThisWeek: Int {
        let completedSets = thisWeeksLogs.reduce(0) { total, log in
            total + log.completedExercises.reduce(0) { $0 + $1.sets.count }
        }

        let activeSets = activeWorkoutStartedThisWeek
            ? activeWorkoutStore.exerciseStates.values.reduce(0) { $0 + $1.loggedSets.count }
            : 0

        return completedSets + activeSets
    }

    private func hasWorkout(on day: Date) -> Bool {
        let calendar = Calendar.current

        let hasLoggedWorkout = logStore.logs.contains {
            calendar.isDate($0.date, inSameDayAs: day)
        }

        let hasActiveWorkoutStartedThatDay = activeWorkoutStore.startedAt.map {
            calendar.isDate($0, inSameDayAs: day)
        } ?? false

        return hasLoggedWorkout || hasActiveWorkoutStartedThatDay
    }

    private var weekDayAccessibilityLabel: String {
        let workoutDayNames = weekDays
            .filter { hasWorkout(on: $0) }
            .map { $0.formatted(.dateTime.weekday(.wide)) }

        guard !workoutDayNames.isEmpty else {
            return "No workouts this week yet"
        }

        return "Workout days this week: " + workoutDayNames.joined(separator: ", ")
    }

    private var weeklySummarySection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SectionHeader(title: "This Week")

                HStack(spacing: AppTheme.Spacing.md) {
                    MetricView(label: "Workouts", value: "\(workoutsThisWeek)")
                    MetricView(label: "Sets", value: "\(setsThisWeek)")
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(weekDays, id: \.self) { day in
                        VStack(spacing: 4) {
                            Text(day.formatted(.dateTime.weekday(.narrow)))
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(AppTheme.tertiaryText)

                            Circle()
                                .fill(
                                    hasWorkout(on: day)
                                        ? AppTheme.accent
                                        : AppTheme.subtleFill
                                )
                                .frame(width: 10, height: 10)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(weekDayAccessibilityLabel)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Recovery

    private var topRecoveryWarning: RecoveryWarning? {
        analyticsCache.recoveryWarnings.max {
            severityRank($0.severity) < severityRank($1.severity)
        }
    }

    private func severityRank(_ severity: WarningSeverity) -> Int {
        switch severity {
        case .low:
            0
        case .medium:
            1
        case .high:
            2
        }
    }

    private func severityColor(_ severity: WarningSeverity) -> Color {
        severity == .high ? AppTheme.error : AppTheme.warning
    }

    @ViewBuilder
    private var recoverySection: some View {
        if let warning = topRecoveryWarning {
            NavigationLink(value: AppRoute.analytics) {
                AppCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Label("Recovery", systemImage: "heart.text.square.fill")
                                .font(AppTheme.Typography.eyebrow)
                                .foregroundStyle(AppTheme.secondaryText)

                            Spacer()

                            ProgressBadge(
                                text: warning.severity.rawValue,
                                color: severityColor(warning.severity)
                            )
                        }

                        Text(warning.title)
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundStyle(Color.primary)

                        Text(warning.message)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.secondaryText)

                        if analyticsCache.recoveryWarnings.count > 1 {
                            let remaining = analyticsCache.recoveryWarnings.count - 1

                            Text("+\(remaining) more recovery warning\(remaining == 1 ? "" : "s")")
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
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
