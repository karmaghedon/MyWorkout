import SwiftUI
import Charts

struct StrengthPoint: Identifiable {
    let id = UUID()
    let date: Date
    let estimatedOneRepMax: Double
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
                            y: .value("Estimated 1RM", settingsStore.settings.displayWeight(Int(point.estimatedOneRepMax.rounded())))
                        )

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Estimated 1RM", settingsStore.settings.displayWeight(Int(point.estimatedOneRepMax.rounded())))
                        )
                    }
                    .frame(height: 300)

                    List(trendData.reversed()) { point in
                        HStack {
                            Text(point.date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text("\(settingsStore.settings.displayWeight(Int(point.estimatedOneRepMax.rounded()))) \(settingsStore.settings.weightUnitLabel)")
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
        let displayValue = settingsStore.settings.displayWeight(Int(latest.estimatedOneRepMax.rounded()))

        VStack(alignment: .leading, spacing: 2) {
            Text("Current Est. 1RM")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(displayValue) \(settingsStore.settings.weightUnitLabel)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.accentMuted)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Strength Data Yet")
                .font(.headline)

            Text("Log a few workouts and your estimated 1RM trends will show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func estimatedOneRepMax(weight: Int, reps: Int) -> Double {
        let weight = Double(weight)
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
