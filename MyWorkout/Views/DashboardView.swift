import SwiftUI

struct DashboardView: View {
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

                    LazyVGrid(columns: columns, spacing: 20) {

                        NavigationLink {
                            StartWorkoutView()
                        } label: {
                            DashboardCard(
                                title: "Start Workout",
                                subtitle: "Begin training session"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            HistoryView()
                        } label: {
                            DashboardCard(
                                title: "History",
                                subtitle: "View previous workouts"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            AnalyticsView()
                        } label: {
                            DashboardCard(
                                title: "Analytics",
                                subtitle: "PRs, volume, trends"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            WorkoutCalendarView()
                        } label: {
                            DashboardCard(
                                title: "Calendar",
                                subtitle: "Training schedule"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            CreateWorkoutTemplateView()
                        } label: {
                            DashboardCard(
                                title: "Templates",
                                subtitle: "Create workout plans"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            TemplateListView()
                        } label: {
                            DashboardCard(
                                title: "Edit Templates",
                                subtitle: "Modify workouts"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            EquipmentInventoryView()
                        } label: {
                            DashboardCard(
                                title: "Equipment",
                                subtitle: "Inventory & plates"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            StrengthTrendView()
                        } label: {
                            DashboardCard(
                                title: "Strength",
                                subtitle: "1RM progression"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
            }
        }
    }
}
