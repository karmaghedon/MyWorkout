import SwiftUI

@main
struct MyWorkoutApp: App {
    @StateObject private var logStore = WorkoutLogStore()
    @StateObject private var templateStore = WorkoutTemplateStore()
    @StateObject private var equipmentStore = EquipmentInventoryStore()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(logStore)
                .environmentObject(templateStore)
                .environmentObject(equipmentStore)
        }
    }
}
