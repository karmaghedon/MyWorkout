import SwiftUI

/// The single "past workouts" screen — replaces what used to be two
/// separate screens (a flat History list and a date-grouped Calendar list)
/// showing the same underlying logs. This keeps the more informative,
/// date-grouped layout with set counts.
struct HistoryView: View {
    @EnvironmentObject var logStore: WorkoutLogStore

    @State private var groupedLogs: [(date: Date, logs: [WorkoutLog])] = []
    @State private var displayedGroupCount = 20
    
    private let pageSize = 20
    
    private var hasMoreGroups: Bool {
        displayedGroupCount < groupedLogs.count
    }
    
    private var visibleGroups: [(date: Date, logs: [WorkoutLog])] {
        Array(groupedLogs.prefix(displayedGroupCount))
    }
    
    var body: some View {
        List {
            ForEach(visibleGroups, id: \.date) { group in
                Section(group.date.formatted(date: .long, time: .omitted)) {
                    ForEach(group.logs) { log in
                        NavigationLink {
                            WorkoutLogDetailView(log: log)
                        } label: {
                            HStack(spacing: AppTheme.Spacing.md) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppTheme.accentMuted)

                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .frame(width: 44, height: 44)
                                .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.workoutName)
                                        .font(.headline)

                                    Text(log.date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text("\(setCount(for: log)) sets")
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            if hasMoreGroups {
                Section {
                    Button {
                        loadMore()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Load More")
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.vertical,8)
                    }
                }
            }
        }
        .navigationTitle("History")
        .overlay {
            if logStore.logs.isEmpty {
                AppEmptyStateView(
                    title: "No Workouts Yet",
                    message: "Finish a workout and it'll show up here.",
                    systemImage: "clock.arrow.circlepath"
                )
            }
        }
        .onAppear {
            regroup()
        }
        .onChange(of: logStore.logs.count) { _, _ in
            regroup()
            displayedGroupCount = pageSize //Reset to first page when logs changed
        }
    }
    
    private func loadMore(){
        displayedGroupCount += pageSize
    }
    
    private func regroup() {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: logStore.logs) { log in
            calendar.startOfDay(for: log.date)
        }

        groupedLogs = grouped
            .map { (date: $0.key, logs: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private func setCount(for log: WorkoutLog) -> Int {
        log.completedExercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
}
