import SwiftUI

@main
struct MyWorkoutApp: App {
    @Environment(\.scenePhase) private var scenePhase

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
    @StateObject private var dailyNutritionLogStore = DailyNutritionLogStore()
    @StateObject private var weeklyBodyReportStore = WeeklyBodyReportStore()

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
                .environmentObject(dailyNutritionLogStore)
                .environmentObject(weeklyBodyReportStore)
                .onAppear {
                    analyticsCache.bind(
                        to: logStore,
                        templateStore: templateStore,
                        customExerciseStore: customExerciseStore
                    )
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background else { return }
            flushAllPendingSaves()
        }
    }

    /// Every store here debounces or backgrounds its actual disk write
    /// rather than performing it synchronously on mutation, and nothing
    /// otherwise guarantees that write completes before the process is
    /// suspended or killed — a background/force-quit shortly after
    /// logging a set, saving a template, or editing a measurement could
    /// otherwise silently lose it. `.background` (not `.inactive`,
    /// which also fires for transient interruptions like a system
    /// alert) is the point after which suspension can follow at any
    /// moment, so this is the last reliable place to force those writes
    /// through.
    ///
    /// Settings and equipment inventory used to be here too, backed by
    /// `UserDefaults` — but `UserDefaults.synchronize()` turned out not
    /// to force anything on modern iOS (confirmed on-device: a setting
    /// changed then killed within a couple of seconds still reverted to
    /// defaults on relaunch, even with a `synchronize()` flush wired
    /// up). Both now write synchronously to a real file instead (see
    /// `UserSettingsStore`/`EquipmentInventoryStore`), so `save()`
    /// itself already blocks until the write has landed — there's
    /// nothing left to flush. `FavoriteExercisesStore` stays on
    /// `UserDefaults` deliberately (see its own doc comment: losing a
    /// favorite isn't worth the same treatment). Stores with no
    /// persistence of their own (analytics cache, HealthKit auth, the
    /// computed weekly report) aren't included either — nothing pending
    /// for them to flush.
    private func flushAllPendingSaves() {
        activeWorkoutStore.flushPendingSave()
        logStore.flushPendingSave()
        templateStore.flushPendingSave()
        bodyMeasurementLogStore.flushPendingSave()
        macroGoalStore.flushPendingSave()
        dailyNutritionLogStore.flushPendingSave()
    }
}
