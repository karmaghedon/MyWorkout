import SwiftUI

/// Analytics used to stack all eight sections below in one long list —
/// genuinely overwhelming, and several sections (Personal Records,
/// Volume by Muscle Group, the two warnings sections) rendered an empty
/// placeholder ("No PRs yet", etc.) even when there was nothing to say,
/// adding clutter rather than removing it. Splitting into a handful of
/// focused tabs means only one related group is on screen at a time;
/// each case below groups sections that answer the same kind of
/// question ("how am I doing overall," "how much am I lifting," "what
/// have I achieved," "what needs my attention").
private enum AnalyticsTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case volume = "Volume"
    case records = "Records"
    case alerts = "Alerts"

    var id: String { rawValue }
}

struct AnalyticsView: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var settingsStore: UserSettingsStore
    @EnvironmentObject var analyticsCache: AnalyticsCache

    @State private var selectedTab: AnalyticsTab = .overview

    var totalWorkouts: Int {
        logStore.logs.count
    }

    var mostRecentWorkoutName: String {
        logStore.logs.first?.workoutName ?? "No workouts yet"
    }

    private var totalAlerts: Int {
        analyticsCache.recoveryWarnings.count + analyticsCache.performanceWarnings.count
    }

    private var hasAnyAlert: Bool {
        totalAlerts > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                ForEach(AnalyticsTab.allCases) { tab in
                    Text(label(for: tab)).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, AppTheme.Spacing.sm)

            List {
                switch selectedTab {
                case .overview:
                    AnalyticsOverviewSection(
                        totalWorkouts: totalWorkouts,
                        totalSets: analyticsCache.totalSets,
                        mostRecentWorkoutName: mostRecentWorkoutName
                    )

                    ConsistencySection(logs: logStore.logs)

                case .volume:
                    VolumeByMuscleGroupSection(volumeByMuscleGroup: analyticsCache.volumeByMuscleGroup)

                    VolumeTrendSection(logs: logStore.logs, settings: settingsStore.settings)

                case .records:
                    PersonalRecordsSection(
                        personalRecords: analyticsCache.personalRecords,
                        settings: settingsStore.settings
                    )

                    RecentWorkoutsSection(logs: logStore.logs)

                case .alerts:
                    alertsContent
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Analytics")
    }

    /// Appends a count to the "Alerts" tab label so there's a hint of
    /// what's inside without having to switch to it first — same idea
    /// as a tab-bar badge, just spelled out since a segmented control
    /// has no badge of its own.
    private func label(for tab: AnalyticsTab) -> String {
        guard tab == .alerts, hasAnyAlert else {
            return tab.rawValue
        }

        return "\(tab.rawValue) (\(totalAlerts))"
    }

    /// One combined "all clear" message when there's genuinely nothing
    /// to flag, instead of two separate sections each saying so — only
    /// shown in the tab a user visits specifically to check for
    /// problems, so it should say as little as possible when there are
    /// none.
    @ViewBuilder
    private var alertsContent: some View {
        if hasAnyAlert {
            RecoveryWarningsSection(warnings: analyticsCache.recoveryWarnings)

            PerformanceWarningsSection(warnings: analyticsCache.performanceWarnings)
        } else {
            Section {
                Label("Nothing needs your attention right now", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
