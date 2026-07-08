import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var settingsStore: UserSettingsStore
    @EnvironmentObject var analyticsCache: AnalyticsCache

    var totalWorkouts: Int {
        logStore.logs.count
    }

    var mostRecentWorkoutName: String {
        logStore.logs.first?.workoutName ?? "No workouts yet"
    }

    var body: some View {
        List {
            AnalyticsOverviewSection(
                totalWorkouts: totalWorkouts,
                totalSets: analyticsCache.totalSets,
                mostRecentWorkoutName: mostRecentWorkoutName
            )

            RecoveryWarningsSection(warnings: analyticsCache.recoveryWarnings)

            PerformanceWarningsSection(warnings: analyticsCache.performanceWarnings)

            VolumeByMuscleGroupSection(volumeByMuscleGroup: analyticsCache.volumeByMuscleGroup)

            PersonalRecordsSection(
                personalRecords: analyticsCache.personalRecord,
                settings: settingsStore.settings
            )

            RecentWorkoutsSection(logs: logStore.logs)
        }
        .navigationTitle("Analytics")
    }
}
