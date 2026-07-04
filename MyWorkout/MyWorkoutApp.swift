import SwiftUI

@main
struct MyWorkoutApp: App {
    
//    private let resetDefaults: Void = {
//        UserDefaults.standard.removeObject(forKey: "equipment_inventory")
//        UserDefaults.standard.removeObject(forKey: "user_settings")
//    }()
    
    @StateObject private var logStore = WorkoutLogStore()
    @StateObject private var templateStore = WorkoutTemplateStore()
    @StateObject private var equipmentStore = EquipmentInventoryStore()
    @StateObject private var settingsStore = UserSettingsStore()
    @StateObject private var activeWorkoutStore = ActiveWorkoutStore()
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(logStore)
                .environmentObject(templateStore)
                .environmentObject(equipmentStore)
                .environmentObject(settingsStore)
                .environmentObject(activeWorkoutStore)
        }
    }
}
