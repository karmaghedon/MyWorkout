import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var settingsStore: UserSettingsStore
    @EnvironmentObject var activeWorkoutStore: ActiveWorkoutStore

    private var columns: [GridItem] {
        [GridItem(.flexible())]
    }

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

                    dashboardSection(title: "Train") {
                        dashboardLink("Start Workout", "Begin training session", StartWorkoutView())
                        dashboardLink("History", "View previous workouts", HistoryView())
                    }

                    dashboardSection(title: "Progress") {
                        dashboardLink("Analytics", "PRs, volume, trends", AnalyticsView())
                        dashboardLink("Strength", "1RM progression", StrengthTrendView())
                    }

                    dashboardSection(title: "Manage") {
                        dashboardLink("Templates", "Create & edit workout plans", TemplatesView())
                        dashboardLink("Equipment", "Inventory & plates", EquipmentInventoryView())
                    }

                    dashboardSection(title: "Settings") {
                        dashboardLink("Settings", "Units, timers, formulas", SettingsView())
                        dashboardLink("Export", "CSV backup & reports", ExportView())
                    }
                }
                .padding(.bottom)
            }
        }
    }

    private func dashboardSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.sectionTitle)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 20) {
                content()
            }
            .padding(.horizontal)
        }
    }

    private var errorReportingStores: [any ErrorReportingStore] {
        [logStore, templateStore, equipmentStore, settingsStore, activeWorkoutStore]
    }

    private var currentErrorMessages: [String] {
        errorReportingStores.compactMap(\.currentError)
    }

    private var errorBanners: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(currentErrorMessages.enumerated()), id: \.offset) { _, message in
                errorBanner(message)
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
