import SwiftUI

struct DashboardStatsView: View {
    @EnvironmentObject var logStore: WorkoutLogStore

    @EnvironmentObject var analyticcsCache: AnalyticsCache

    private var totalAlerts: Int {
        analyticcsCache.recoveryWarnings.count + analyticcsCache.performanceWarnings.count
    }

    private var totalWorkouts: Int {
        logStore.logs.count
    }

    private var latestWorkout: String {
        logStore.logs.first?.workoutName ?? "None"
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SectionHeader(title: "Overview")

                HStack(spacing: AppTheme.Spacing.md) {
                    MetricView(label: "Workouts", value: "\(totalWorkouts)")
                    MetricView(label: "Latest", value: latestWorkout)
                    MetricView(label: "Alerts", value: "\(totalAlerts)")
                }

                if totalAlerts > 0 {
                    NavigationLink {
                        AnalyticsView()
                    } label: {
                        Label("\(totalAlerts) item(s) need attention", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.warning)
                            .font(AppTheme.Typography.label)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
}
