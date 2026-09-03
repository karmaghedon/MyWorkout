import SwiftUI

/// A weekly nudge to log waist and neck — unlike weight, these are only
/// needed once a week to keep the Navy body-fat estimate
/// (`NavyBodyFatCalculator`) current, so there's no daily-entry banner
/// for them.
///
/// Visible starting the most recent Saturday (inclusive of today, if
/// today is Saturday) and every day after that until both waist and
/// neck have been logged since then; automatically resets the
/// following Saturday. A missed Saturday still gets reminded on Sunday,
/// Monday, etc. — the banner only clears once the readings are actually
/// logged, not just because a day passed.
struct WeeklyMeasurementsReminderBanner: View {
    @EnvironmentObject private var bodyMeasurementLogStore: BodyMeasurementLogStore

    private let healthKitService: any BodyMetricsHealthKitServicing

    @State private var hasWaistSincePeriodStart = false
    @State private var isLoaded = false

    init(
        healthKitService: any BodyMetricsHealthKitServicing = BodyMetricsHealthKitService()
    ) {
        self.healthKitService = healthKitService
    }

    var body: some View {
        Group {
            if isLoaded && needsReminder {
                NavigationLink(value: AppRoute.logBodyMeasurements) {
                    AppCard(backgroundColor: AppTheme.warning.opacity(0.15)) {
                        WorkoutCard(
                            systemImage: "ruler.fill",
                            title: "Log This Week's Waist & Neck"
                        ) {
                            Text("Just once a week \u{2014} used to estimate body fat %.")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
        .onAppear {
            // Not `.task`: this view's parent (`DashboardView`) stays
            // mounted in its tab's `NavigationStack` across tab
            // switches, so `.task` (tied to view identity, fires once
            // per lifetime) would never re-check after the user logs
            // waist/neck elsewhere and comes back to Home — `.onAppear`
            // fires every time this becomes visible again, keeping the
            // banner's dismissal reflecting the latest data.
            Task {
                await reload()
            }
        }
    }

    private var needsReminder: Bool {
        !hasWaistSincePeriodStart || !hasNeckSincePeriodStart
    }

    private var hasNeckSincePeriodStart: Bool {
        let start = Self.mostRecentSaturday(from: .now, calendar: .current)

        return bodyMeasurementLogStore.logs.contains {
            $0.neckCm != nil && $0.date >= start
        }
    }

    private func reload() async {
        let start = Self.mostRecentSaturday(from: .now, calendar: .current)

        do {
            let waistSamples = try await healthKitService.waistSamples(since: start)
            hasWaistSincePeriodStart = !waistSamples.isEmpty
        } catch {
            // Fail safe: don't nag if the check itself couldn't run.
            hasWaistSincePeriodStart = true
        }

        isLoaded = true
    }

    private static func mostRecentSaturday(from date: Date, calendar: Calendar) -> Date {
        let today = calendar.startOfDay(for: date)
        // `.weekday` is always 1=Sunday...7=Saturday regardless of the
        // calendar's `firstWeekday` setting, which only affects
        // `weekOfYear`-style computations, not this raw component.
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceSaturday = (weekday - 7 + 7) % 7

        return calendar.date(byAdding: .day, value: -daysSinceSaturday, to: today) ?? today
    }
}
