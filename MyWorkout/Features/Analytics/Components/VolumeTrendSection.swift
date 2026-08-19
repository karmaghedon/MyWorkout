import SwiftUI
import Charts

/// Total training volume (weight × reps, summed across every set) per
/// week, over the most recent weeks with data. Distinct from
/// `VolumeByMuscleGroupSection`, which shows current totals split by
/// muscle group rather than how volume has moved over time — the
/// Design Blueprint's F6 goal list calls these out as two separate
/// items ("Volume Trends" vs "Muscle Distribution").
struct VolumeTrendSection: View {
    let logs: [WorkoutLog]
    let settings: UserSettings

    private struct WeeklyVolume: Identifiable {
        let weekStart: Date
        let volumePounds: Double
        var id: Date { weekStart }
    }

    private var weeklyVolumes: [WeeklyVolume] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: logs) { log in
            calendar.dateInterval(of: .weekOfYear, for: log.date)?.start ?? log.date
        }

        return grouped
            .map { weekStart, weekLogs in
                let volume = weekLogs.reduce(0.0) { total, log in
                    total + WorkoutSessionEngine.totalVolume(in: log)
                }

                return WeeklyVolume(weekStart: weekStart, volumePounds: volume)
            }
            .sorted { $0.weekStart < $1.weekStart }
            .suffix(12)
            .map { $0 }
    }

    var body: some View {
        Section {
            if weeklyVolumes.count < 2 {
                Text("Log a few more weeks of workouts to see your volume trend.")
                    .foregroundStyle(.secondary)
            } else {
                Chart(weeklyVolumes) { point in
                    BarMark(
                        x: .value("Week", point.weekStart, unit: .weekOfYear),
                        y: .value(
                            "Volume",
                            settings.displayWeight(point.volumePounds)
                        )
                    )
                    .foregroundStyle(AppTheme.accent)
                }
                .frame(height: 180)
                .accessibilityLabel(
                    "Weekly training volume over the last \(weeklyVolumes.count) weeks"
                )
            }
        } header: {
            Label("Volume Trend", systemImage: "chart.bar.xaxis")
        }
    }
}
