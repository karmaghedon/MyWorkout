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
    @Environment(\.scenePhase) private var scenePhase

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
            if needsReminder {
                NavigationLink(value: AppRoute.logBodyMeasurements) {
                    AppCard(backgroundColor: AppTheme.warning.opacity(0.15)) {
                        WorkoutCard(
                            systemImage: "ruler.fill",
                            title: "Log This Week's Waist & Neck"
                        ) {
                            // Explanatory subtitle ("used to estimate
                            // body fat %") removed — it's the kind of
                            // one-time context a future walkthrough/
                            // onboarding tool should cover, not
                            // something worth showing every single time
                            // this banner appears. See the walkthrough
                            // tool entry in the roadmap doc.
                            EmptyView()
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
        .onChange(of: scenePhase) { _, newPhase in
            // `.onAppear` alone only fires when this view is newly
            // inserted into the hierarchy — not when the app is simply
            // backgrounded and reopened while Home stayed mounted the
            // whole time (e.g. left open overnight without ever
            // navigating away). Without this, the period-start
            // computation — which depends on today's date — can stay
            // stuck on whatever day the view last appeared, so the
            // banner would never notice a new Saturday arrived until
            // something else happened to remount it.
            guard newPhase == .active else { return }

            Task {
                await reload()
            }
        }
    }

    /// Neck's half of the check is a plain, synchronous read of local
    /// data — always fresh on every render, no loading state needed.
    /// Waist's half depends on an async HealthKit round-trip, cached in
    /// `isLoaded`/`hasWaistSincePeriodStart` so it isn't re-queried on
    /// every render — but that meant the *entire* banner used to wait
    /// on it via a blanket `isLoaded &&` gate, so if that HealthKit
    /// call was ever slow to resolve (or simply hadn't been kicked off
    /// yet), the banner stayed hidden even in the common case where the
    /// always-fresh neck check alone already knows a reminder is
    /// needed. Missing neck is checked first specifically so it can
    /// answer immediately without any dependency on the HealthKit
    /// round-trip's timing at all; only when neck is already logged
    /// does whether to show hinge on waist's (necessarily loading-
    /// gated) status.
    private var needsReminder: Bool {
        guard hasNeckSincePeriodStart else { return true }
        guard isLoaded else { return false }
        return !hasWaistSincePeriodStart
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
