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
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(logStore)
                .environmentObject(templateStore)
                .environmentObject(equipmentStore)
                .environmentObject(settingsStore)
                .environmentObject(activeWorkoutStore)
                .environmentObject(analyticsCache)
                .environmentObject(customExerciseStore)
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
