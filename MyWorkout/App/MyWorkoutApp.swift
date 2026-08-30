import SwiftUI

@main
struct MyWorkoutApp: App {
    @StateObject private var logStore = WorkoutLogStore()
    @StateObject private var templateStore = WorkoutTemplateStore()
    @StateObject private var equipmentStore = EquipmentInventoryStore()
    @StateObject private var settingsStore = UserSettingsStore()
    @StateObject private var activeWorkoutStore = ActiveWorkoutStore()
    @StateObject private var customExerciseStore = CustomExerciseStore()
    @StateObject private var analyticsCache = AnalyticsCache()
    @StateObject private var favoriteExercisesStore = FavoriteExercisesStore()
    @StateObject private var healthKitAuthorizationManager = HealthKitAuthorizationManager()
    @StateObject private var bodyMeasurementLogStore = BodyMeasurementLogStore()
    @StateObject private var macroGoalStore = MacroGoalStore()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .environmentObject(logStore)
                .environmentObject(templateStore)
                .environmentObject(equipmentStore)
                .environmentObject(settingsStore)
                .environmentObject(activeWorkoutStore)
                .environmentObject(analyticsCache)
                .environmentObject(customExerciseStore)
                .environmentObject(favoriteExercisesStore)
                .environmentObject(healthKitAuthorizationManager)
                .environmentObject(bodyMeasurementLogStore)
                .environmentObject(macroGoalStore)
                .onAppear {
                    analyticsCache.bind(
                        to: logStore,
                        templateStore: templateStore,
                        customExerciseStore: customExerciseStore
                    )
                }
        }
    }
}
