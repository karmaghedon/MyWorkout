import SwiftUI

/// The "This Week" card — workout count/sets plus a 7-day strip where
/// each day shows two independent signals: a small dot for whether a
/// workout happened that day (existing behavior), and a surrounding
/// ring showing how much of {weight, calories} was logged that day —
/// empty, half, or full for 0, 1, or 2 of those two logged. Weight
/// comes from HealthKit (fetched fresh via `.onAppear`); calories come
/// from the already-reactive `DailyNutritionLogStore`.
///
/// Each day is tappable: a confirmation dialog offers "Log Weight" or
/// "Log Nutrition" for that specific date, presenting the same screens
/// used elsewhere (`LogWeightView`/`LogNutritionView`, both generalized
/// to accept an arbitrary date) so a past day's data can be added or
/// corrected, not just today's.
struct WeeklySummaryCard: View {
    @EnvironmentObject private var logStore: WorkoutLogStore
    @EnvironmentObject private var activeWorkoutStore: ActiveWorkoutStore
    @EnvironmentObject private var dailyNutritionLogStore: DailyNutritionLogStore

    private let healthKitService: any BodyMetricsHealthKitServicing

    @State private var weightSamplesThisWeek: [DatedValue] = []
    @State private var tappedDay: Date?
    @State private var activeSheet: ActiveSheet?

    init(
        healthKitService: any BodyMetricsHealthKitServicing = BodyMetricsHealthKitService()
    ) {
        self.healthKitService = healthKitService
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SectionHeader(title: "This Week")

                HStack(spacing: AppTheme.Spacing.md) {
                    MetricView(label: "Workouts", value: "\(workoutsThisWeek)")
                    MetricView(label: "Sets", value: "\(setsThisWeek)")
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(weekDays, id: \.self) { day in
                        Button {
                            tappedDay = day
                        } label: {
                            VStack(spacing: 4) {
                                Text(day.formatted(.dateTime.weekday(.narrow)))
                                    .font(AppTheme.Typography.footnote)
                                    .foregroundStyle(AppTheme.tertiaryText)

                                dayIndicator(for: day)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(weekDayAccessibilityLabel)
            }
        }
        .padding(.horizontal)
        .onAppear {
            // Not `.task`: this card's tab keeps its NavigationStack
            // mounted across tab switches, so `.task` (tied to view
            // identity, fires once per lifetime) would never reload
            // after logging a new weigh-in elsewhere and returning to
            // Home. `.onAppear` fires every time this becomes visible
            // again.
            Task {
                await loadWeightSamples()
            }
        }
        .confirmationDialog(
            "Edit This Day",
            isPresented: Binding(
                get: { tappedDay != nil },
                set: { isPresented in
                    if !isPresented { tappedDay = nil }
                }
            ),
            titleVisibility: .visible,
            presenting: tappedDay
        ) { day in
            Button("Log Weight") {
                activeSheet = .weight(day)
            }

            Button("Log Nutrition") {
                activeSheet = .nutrition(day)
            }

            Button("Cancel", role: .cancel) {}
        } message: { day in
            Text(day.formatted(date: .abbreviated, time: .omitted))
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .weight(let date):
                    LogWeightView(date: date)
                case .nutrition(let date):
                    LogNutritionView(date: date)
                }
            }
        }
        .onChange(of: activeSheet) { _, newValue in
            // The sheet dismissing doesn't make this card "appear"
            // again (it was never hidden, just covered), so `.onAppear`
            // alone wouldn't catch a weigh-in just logged from the
            // sheet — refresh explicitly the moment it closes.
            guard newValue == nil else { return }

            Task {
                await loadWeightSamples()
            }
        }
    }

    private func dayIndicator(for day: Date) -> some View {
        ZStack {
            Circle()
                .stroke(AppTheme.subtleFill, lineWidth: 2)
                .frame(width: 18, height: 18)

            Circle()
                .trim(from: 0, to: loggingProgress(on: day))
                .stroke(AppTheme.success, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 18, height: 18)

            Circle()
                .fill(hasWorkout(on: day) ? AppTheme.accent : AppTheme.subtleFill)
                .frame(width: 10, height: 10)
        }
    }

    // MARK: - Week window

    /// A rolling 7-day window ending today (inclusive), not a fixed
    /// calendar week — see `DashboardView`'s prior fix for why a fixed
    /// calendar week silently resets to empty on the first day of a
    /// new week.
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<7).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -(6 - daysAgo), to: today)
        }
    }

    private var recentWeekInterval: DateInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = weekDays.first ?? today
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? .now

        return DateInterval(start: start, end: end)
    }

    private var thisWeeksLogs: [WorkoutLog] {
        logStore.logs.filter {
            recentWeekInterval.contains($0.date)
        }
    }

    private var activeWorkoutStartedThisWeek: Bool {
        guard let startedAt = activeWorkoutStore.startedAt else {
            return false
        }

        return recentWeekInterval.contains(startedAt)
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

    // MARK: - Logging progress (weight + calories)

    private func hasWeightLogged(on day: Date) -> Bool {
        let calendar = Calendar.current

        return weightSamplesThisWeek.contains {
            calendar.isDate($0.date, inSameDayAs: day)
        }
    }

    private func hasCaloriesLogged(on day: Date) -> Bool {
        dailyNutritionLogStore.entry(on: day) != nil
    }

    private func loggingProgress(on day: Date) -> Double {
        let loggedCount = [hasWeightLogged(on: day), hasCaloriesLogged(on: day)]
            .filter { $0 }
            .count

        return Double(loggedCount) / 2.0
    }

    private func loadWeightSamples() async {
        guard let start = weekDays.first else { return }

        do {
            weightSamplesThisWeek = try await healthKitService.weightSamples(since: start)
        } catch {
            weightSamplesThisWeek = []
        }
    }
}

private enum ActiveSheet: Identifiable, Equatable {
    case weight(Date)
    case nutrition(Date)

    var id: String {
        switch self {
        case .weight(let date):
            "weight-\(date.timeIntervalSince1970)"
        case .nutrition(let date):
            "nutrition-\(date.timeIntervalSince1970)"
        }
    }
}
