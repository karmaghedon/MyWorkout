import SwiftUI
import Charts

struct StrengthPoint: Identifiable {

    let date: Date
    let estimatedOneRepMax: Double
    
    var id: String {
        "\(date.timeIntervalSince1970)-\(estimatedOneRepMax)"
    }
}

struct StrengthTrendView: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var settingsStore: UserSettingsStore

    @State private var selectedExerciseName: String = ""

    private var exerciseNames: [String] {
        Array(Set(logStore.logs.flatMap { log in
            log.completedExercises.map { $0.exerciseName }
        }))
        .sorted()
    }

    private var trendData: [StrengthPoint] {
        logStore.logs
            .flatMap { log in
                log.completedExercises
                    .filter { $0.exerciseName == selectedExerciseName }
                    .flatMap { exercise in
                        exercise.sets.map { set in
                            StrengthPoint(
                                date: log.date,
                                estimatedOneRepMax: estimatedOneRepMax(weight: set.weight, reps: set.reps)
                            )
                        }
                    }
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if exerciseNames.isEmpty {
                emptyState
            } else {
                Picker("Exercise", selection: $selectedExerciseName) {
                    ForEach(exerciseNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)

                if let latest = trendData.last {
                    currentBestCard(latest: latest)

                    Chart(trendData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Estimated 1RM", settingsStore.settings.displayWeight(point.estimatedOneRepMax))
                        )

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Estimated 1RM", settingsStore.settings.displayWeight(point.estimatedOneRepMax))
                        )
                    }
                    .frame(height: 300)

                    List(trendData.reversed()) { point in
                        HStack {
                            Text(point.date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text("\(formatWeight(settingsStore.settings.displayWeight(point.estimatedOneRepMax))) \(settingsStore.settings.weightUnitLabel)")
                                .bold()
                        }
                    }
                } else {
                    Text("No strength trend data yet")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .navigationTitle("Strength Trends")
        .onAppear {
            if selectedExerciseName.isEmpty {
                selectedExerciseName = exerciseNames.first ?? ""
            }
        }
    }

    @ViewBuilder
    private func currentBestCard(latest: StrengthPoint) -> some View {
        let displayValue = formatWeight(settingsStore.settings.displayWeight(latest.estimatedOneRepMax))

        MetricCard(
            label: "Current Est. 1RM",
            value: "\(displayValue) \(settingsStore.settings.weightUnitLabel)"
        )
    }

    private var emptyState: some View {
        AppEmptyStateView(
            title: "No Strength Data Yet",
            message: "Log a few workouts and your estimated 1RM trends will show up here.",
            systemImage: "chart.line.uptrend.xyaxis"
        )
        .frame(maxWidth: .infinity)
    }

    private func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
        let reps = Double(reps)

        switch settingsStore.settings.oneRepMaxFormula {
        case .epley:
            return weight * (1.0 + reps / 30.0)

        case .brzycki:
            guard reps < 37 else { return weight }
            return weight * (36.0 / (37.0 - reps))
        }
    }
}
