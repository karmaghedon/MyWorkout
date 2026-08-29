import SwiftUI

struct AnalyticsOverviewSection: View {
    let totalWorkouts: Int
    let totalSets: Int
    let mostRecentWorkoutName: String

    var body: some View {
        Section {
            HStack {
                Text("Total Workouts")
                Spacer()
                Text("\(totalWorkouts)")
                    .bold()
            }
            .accessibilityElement(children: .combine)

            HStack {
                Text("Total Sets")
                Spacer()
                Text("\(totalSets)")
                    .bold()
            }
            .accessibilityElement(children: .combine)

            HStack {
                Text("Latest Workout")
                Spacer()
                Text(mostRecentWorkoutName)
                    .bold()
            }
            .accessibilityElement(children: .combine)
        } header: {
            Label("Overview", systemImage: "chart.bar.fill")
        }
    }
}

#Preview {
    List {
        AnalyticsOverviewSection(totalWorkouts: 42, totalSets: 318, mostRecentWorkoutName: "Push Day")
    }
}
