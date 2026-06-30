import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var logStore: WorkoutLogStore

    var body: some View {
        List(logStore.logs) { log in
            NavigationLink {
                WorkoutLogDetailView(log: log)
            } label: {
                VStack(alignment: .leading) {
                    Text(log.workoutName)
                        .font(.headline)

                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
            }
        }
        .navigationTitle("History")
    }
}
