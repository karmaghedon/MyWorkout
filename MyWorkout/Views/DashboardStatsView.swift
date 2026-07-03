import SwiftUI

struct DashboardStatsView: View {
    @EnvironmentObject var logStore: WorkoutLogStore

    private var recoveryWarnings: [RecoveryWarning] {
        RecoveryAnalyzer.warnings(logs: logStore.logs)
    }

    private var performanceWarnings: [ExercisePerformanceWarning] {
        ExercisePerformanceAnalyzer.warnings(logs: logStore.logs)
    }

    private var totalAlerts: Int {
        recoveryWarnings.count + performanceWarnings.count
    }

    private var totalWorkouts: Int {
        logStore.logs.count
    }

    private var latestWorkout: String {
        logStore.logs.first?.workoutName ?? "None"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Overview")
                .font(AppTheme.Typography.sectionTitle)

            HStack(spacing: AppTheme.Spacing.md) {
                statCard(title: "Workouts", value: "\(totalWorkouts)")
                statCard(title: "Latest", value: latestWorkout)
                statCard(title: "Alerts", value: "\(totalAlerts)")
            }

            if totalAlerts > 0 {
                NavigationLink {
                    AnalyticsView()
                } label: {
                    Label("\(totalAlerts) item(s) need attention", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(AppTheme.Typography.label)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .padding(.horizontal)
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title.uppercased())
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            Text(value)
                .font(AppTheme.Typography.label)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
