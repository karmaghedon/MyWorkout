import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var settingsStore: UserSettingsStore

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("MyWorkout")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal)

                    errorBanners
                    
                    DashboardStatsView()

                    LazyVGrid(columns: columns, spacing: 20) {
                        dashboardLink("Start Workout", "Begin training session", StartWorkoutView())
                        dashboardLink("History", "View previous workouts", HistoryView())
                        dashboardLink("Analytics", "PRs, volume, trends", AnalyticsView())
                        dashboardLink("Calendar", "Training schedule", WorkoutCalendarView())
                        dashboardLink("Templates", "Create workout plans", CreateWorkoutTemplateView())
                        dashboardLink("Edit Templates", "Modify workouts", TemplateListView())
                        dashboardLink("Equipment", "Inventory & plates", EquipmentInventoryView())
                        dashboardLink("Strength", "1RM progression", StrengthTrendView())
                        dashboardLink("Settings", "Units, timers, formulas", SettingsView())
                        dashboardLink("Export", "CSV backup & reports", ExportView())
                    }
                    .padding()
                }
            }
        }
    }

    private var errorBanners: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = logStore.lastSaveError {
                errorBanner(error)
            }

            if let error = templateStore.lastSaveError ?? templateStore.lastLoadError {
                errorBanner(error)
            }

            if let error = equipmentStore.lastSaveError ?? equipmentStore.lastLoadError {
                errorBanner(error)
            }

            if let error = settingsStore.lastSaveError ?? settingsStore.lastLoadError {
                errorBanner(error)
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .foregroundStyle(.red)
            .padding()
            .background(.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
    }

    private func dashboardLink<Destination: View>(
        _ title: String,
        _ subtitle: String,
        _ destination: Destination
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            DashboardCard(title: title, subtitle: subtitle)
        }
        .buttonStyle(.plain)
    }
}
