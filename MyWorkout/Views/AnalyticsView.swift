import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var settingsStore: UserSettingsStore
    
    var totalWorkouts: Int {
        logStore.logs.count
    }

    var totalSets: Int {
        logStore.logs.reduce(0) { total, log in
            total + log.completedExercises.reduce(0) { exerciseTotal, exercise in
                exerciseTotal + exercise.sets.count
            }
        }
    }

    var mostRecentWorkoutName: String {
        logStore.logs.first?.workoutName ?? "—"
    }

    var volumeByMuscleGroup: [(muscle: String, sets: Int)] {
        var result: [String: Int] = [:]

        for log in logStore.logs {
            for completedExercise in log.completedExercises {
                guard let exercise = SeedData.exercises.first(where: {
                    $0.name == completedExercise.exerciseName
                }) else {
                    continue
                }

                result[exercise.muscleGroup, default: 0] += completedExercise.sets.count
            }
        }

        return result
            .map { (muscle: $0.key, sets: $0.value) }
            .sorted { $0.sets > $1.sets }
    }

    var personalRecords: [(exercise: String, weight: Int, reps: Int)] {
        var bestByExercise: [String: LoggedSet] = [:]

        for log in logStore.logs {
            for completedExercise in log.completedExercises {
                for set in completedExercise.sets {
                    let currentBest = bestByExercise[completedExercise.exerciseName]

                    if currentBest == nil || isBetter(set, than: currentBest!) {
                        bestByExercise[completedExercise.exerciseName] = set
                    }
                }
            }
        }

        return bestByExercise
            .map { (exercise: $0.key, weight: $0.value.weight, reps: $0.value.reps) }
            .sorted { $0.exercise < $1.exercise }
    }

    var body: some View {
        List {
            Section {
                overviewTiles
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Volume by Muscle Group") {
                if volumeByMuscleGroup.isEmpty {
                    Text("No volume data yet")
                        .foregroundStyle(.secondary)
                } else {
                    volumeChart
                        .frame(height: CGFloat(volumeByMuscleGroup.count) * 34 + 20)
                        .padding(.vertical, AppTheme.Spacing.xs)
                }
            }

            Section("Personal Records") {
                if personalRecords.isEmpty {
                    Text("No PRs yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(personalRecords, id: \.exercise) { pr in
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 20)

                            Text(pr.exercise)

                            Spacer()

                            Text("\(settingsStore.settings.displayWeight(pr.weight)) \(settingsStore.settings.weightUnitLabel) × \(pr.reps)")
                        }
                    }
                }
            }

            Section("Recent Workouts") {
                ForEach(logStore.logs.prefix(5)) { log in
                    NavigationLink {
                        WorkoutLogDetailView(log: log)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.workoutName)
                                .font(.headline)

                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\(setCount(for: log)) sets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Analytics")
    }

    // MARK: - Overview

    private var overviewTiles: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            statTile(value: "\(totalWorkouts)", label: "Workouts")
            statTile(value: "\(totalSets)", label: "Total Sets")
            statTile(value: mostRecentWorkoutName, label: "Latest", isTextValue: true)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private func statTile(value: String, label: String, isTextValue: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(isTextValue ? AppTheme.Typography.label : AppTheme.Typography.numeric(24))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(isTextValue ? .primary : AppTheme.accent)

            Text(label.uppercased())
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.subtleFill)
        )
    }

    // MARK: - Volume chart

    private var volumeChart: some View {
        Chart(volumeByMuscleGroup, id: \.muscle) { item in
            BarMark(
                x: .value("Sets", item.sets),
                y: .value("Muscle Group", item.muscle)
            )
            .foregroundStyle(AppTheme.accent.gradient)
            .cornerRadius(4)
            .annotation(position: .trailing) {
                Text("\(item.sets)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func setCount(for log: WorkoutLog) -> Int {
        log.completedExercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }

    private func isBetter(_ newSet: LoggedSet, than oldSet: LoggedSet) -> Bool {
        if newSet.weight > oldSet.weight {
            return true
        }

        if newSet.weight == oldSet.weight && newSet.reps > oldSet.reps {
            return true
        }

        return false
    }
}
