import SwiftUI

struct WorkoutCalendarView: View {
    @EnvironmentObject var logStore: WorkoutLogStore

    private var groupedLogs: [(date: Date, logs: [WorkoutLog])] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: logStore.logs) { log in
            calendar.startOfDay(for: log.date)
        }

        return grouped
            .map { (date: $0.key, logs: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            ForEach(groupedLogs, id: \.date) { group in
                Section(group.date.formatted(date: .long, time: .omitted)) {
                    ForEach(group.logs) { log in
                        NavigationLink {
                            WorkoutLogDetailView(log: log)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(log.workoutName)
                                    .font(.headline)

                                Text(log.date.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("\(setCount(for: log)) sets")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Workout Calendar")
    }

    private func setCount(for log: WorkoutLog) -> Int {
        log.completedExercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
}
