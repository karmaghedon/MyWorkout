import SwiftUI

/// A current streak (consecutive weeks with at least one workout,
/// counting back from this week) plus a 12-week activity strip —
/// the Design Blueprint's F6 "Consistency" goal.
struct ConsistencySection: View {
    let logs: [WorkoutLog]

    private struct WeekActivity {
        let weekStart: Date
        let hasWorkout: Bool
    }

    private var recentWeeks: [WeekActivity] {
        let calendar = Calendar.current

        guard let thisWeekStart = calendar.dateInterval(
            of: .weekOfYear,
            for: .now
        )?.start else {
            return []
        }

        return stride(from: 11, through: 0, by: -1).compactMap { offset -> WeekActivity? in
            guard let weekStart = calendar.date(
                byAdding: .weekOfYear,
                value: -offset,
                to: thisWeekStart
            ), let interval = calendar.dateInterval(
                of: .weekOfYear,
                for: weekStart
            ) else {
                return nil
            }

            let hasWorkout = logs.contains { interval.contains($0.date) }

            return WeekActivity(weekStart: weekStart, hasWorkout: hasWorkout)
        }
    }

    private var currentStreak: Int {
        var streak = 0

        for week in recentWeeks.reversed() {
            guard week.hasWorkout else {
                break
            }

            streak += 1
        }

        return streak
    }

    private var activeWeekCount: Int {
        recentWeeks.filter(\.hasWorkout).count
    }

    private var accessibilitySummary: String {
        "\(activeWeekCount) of the last \(recentWeeks.count) weeks had a workout. "
        + "Current streak: \(currentStreak) week\(currentStreak == 1 ? "" : "s")."
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    MetricView(
                        label: "Current Streak",
                        value: "\(currentStreak) wk\(currentStreak == 1 ? "" : "s")"
                    )

                    MetricView(
                        label: "Active Weeks",
                        value: "\(activeWeekCount)/\(recentWeeks.count)"
                    )
                }

                HStack(spacing: 4) {
                    ForEach(recentWeeks, id: \.weekStart) { week in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(
                                week.hasWorkout
                                    ? AppTheme.accent
                                    : AppTheme.subtleFill
                            )
                            .frame(height: 20)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary)
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        } header: {
            Label("Consistency", systemImage: "flame.fill")
        }
    }
}
