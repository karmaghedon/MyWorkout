import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var settingsStore: UserSettingsStore
    @EnvironmentObject var analyticsCache: AnalyticsCache

    var totalWorkouts: Int {
        logStore.logs.count
    }

//    var totalSets: Int {
//        logStore.logs.reduce(0) { total, log in
//            total + log.completedExercises.reduce(0) { exerciseTotal, exercise in
//                exerciseTotal + exercise.sets.count
//            }
//        }
//    }

    var mostRecentWorkoutName: String {
        logStore.logs.first?.workoutName ?? "No workouts yet"
    }

//    var recoveryWarnings: [RecoveryWarning] {
//        RecoveryAnalyzer.warnings(logs: logStore.logs)
//    }
//
//    var performanceWarnings: [ExercisePerformanceWarning] {
//        ExercisePerformanceAnalyzer.warnings(logs: logStore.logs)
//    }
//
//    var volumeByMuscleGroup: [(muscle: String, sets: Int)] {
//        var result: [String: Int] = [:]
//
//        for log in logStore.logs {
//            for completedExercise in log.completedExercises {
//                guard let exercise = SeedData.exercises.first(where: {
//                    if let completedID = completedExercise.exerciseID {
//                        return $0.id == completedID
//                    }
//
//                    return $0.name == completedExercise.exerciseName
//                }) else {
//                    continue
//                }
//
//                result[exercise.muscleGroup, default: 0] += completedExercise.sets.count
//            }
//        }
//
//        return result
//            .map { (muscle: $0.key, sets: $0.value) }
//            .sorted { $0.sets > $1.sets }
//    }
//
//    var personalRecords: [(exercise: String, weight: Int, reps: Int)] {
//        var bestByExercise: [String: (name: String, set: LoggedSet)] = [:]
//
//        for log in logStore.logs {
//            for completedExercise in log.completedExercises {
//                let key = completedExercise.exerciseID?.uuidString ?? completedExercise.exerciseName
//
//                for set in completedExercise.sets {
//                    let currentBest = bestByExercise[key]?.set
//
//                    if currentBest == nil || isBetter(set, than: currentBest!) {
//                        bestByExercise[key] = (
//                            name: completedExercise.exerciseName,
//                            set: set
//                        )
//                    }
//                }
//            }
//        }
//
//        return bestByExercise
//            .map {
//                (
//                    exercise: $0.value.name,
//                    weight: $0.value.set.weight,
//                    reps: $0.value.set.reps
//                )
//            }
//            .sorted { $0.exercise < $1.exercise }
//    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Total Workouts")
                    Spacer()
                    Text("\(totalWorkouts)")
                        .bold()
                }

                HStack {
                    Text("Total Sets")
                    Spacer()
                    Text("\(analyticsCache.totalSets)")
                        .bold()
                }

                HStack {
                    Text("Latest Workout")
                    Spacer()
                    Text(mostRecentWorkoutName)
                        .bold()
                }
            } header: {
                Label("Overview", systemImage: "chart.bar.fill")
            }

            Section {
                if analyticsCache.recoveryWarnings.isEmpty {
                    Text("No recovery warnings")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(analyticsCache.recoveryWarnings) { warning in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(warning.title)
                                    .font(.headline)

                                Spacer()

                                Text(warning.severity.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.orange.opacity(0.2))
                                    .clipShape(Capsule())
                            }

                            Text(warning.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Suggested action: \(warning.recommendation)")
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Label("Recovery / Fatigue", systemImage: "heart.text.square.fill")
            }

            Section {
                if analyticsCache.performanceWarnings.isEmpty {
                    Text("No performance warnings")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(analyticsCache.performanceWarnings) { warning in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(warning.exerciseName)
                                .font(.headline)

                            Text(warning.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Label("Performance Warnings", systemImage: "exclamationmark.triangle.fill")
            }

            Section {
                if analyticsCache.volumeByMuscleGroup.isEmpty {
                    Text("No volume data yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(analyticsCache.volumeByMuscleGroup, id: \.muscle) { item in
                        HStack {
                            Text(item.muscle)
                            Spacer()
                            Text("\(item.sets) sets")
                                .bold()
                        }
                    }
                }
            } header: {
                Label("Volume by Muscle Group", systemImage: "chart.pie.fill")
            }

            Section {
                if analyticsCache.personalRecord.isEmpty {
                    Text("No PRs yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(analyticsCache.personalRecord, id: \.exercise) { pr in
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                                .accessibilityHidden(true)

                            Text(pr.exercise)

                            Spacer()

                            Text("\(formatWeight(settingsStore.settings.displayWeight(pr.weight))) \(settingsStore.settings.weightUnitLabel) × \(pr.reps)")
                                .bold()
                        }
                    }
                }
            } header: {
                Label("Personal Records", systemImage: "trophy.fill")
            }

            Section {
                ForEach(logStore.logs.prefix(5)) { log in
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

                                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("\(setCount(for: log)) sets")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Label("Recent Workouts", systemImage: "clock.arrow.circlepath")
            }
        }
        .navigationTitle("Analytics")
    }

    private func setCount(for log: WorkoutLog) -> Int {
        log.completedExercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }

//    private func isBetter(_ newSet: LoggedSet, than oldSet: LoggedSet) -> Bool {
//        if newSet.weight > oldSet.weight {
//            return true
//        }
//
//        if newSet.weight == oldSet.weight && newSet.reps > oldSet.reps {
//            return true
//        }
//
//        return false
//    }
}
