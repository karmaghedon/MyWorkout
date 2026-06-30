import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var logStore: WorkoutLogStore

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
        logStore.logs.first?.workoutName ?? "No workouts yet"
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
            Section("Overview") {
                HStack {
                    Text("Total Workouts")
                    Spacer()
                    Text("\(totalWorkouts)")
                        .bold()
                }

                HStack {
                    Text("Total Sets")
                    Spacer()
                    Text("\(totalSets)")
                        .bold()
                }

                HStack {
                    Text("Latest Workout")
                    Spacer()
                    Text(mostRecentWorkoutName)
                        .bold()
                }
            }

            Section("Volume by Muscle Group") {
                if volumeByMuscleGroup.isEmpty {
                    Text("No volume data yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(volumeByMuscleGroup, id: \.muscle) { item in
                        HStack {
                            Text(item.muscle)
                            Spacer()
                            Text("\(item.sets) sets")
                                .bold()
                        }
                    }
                }
            }

            Section("Personal Records") {
                if personalRecords.isEmpty {
                    Text("No PRs yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(personalRecords, id: \.exercise) { pr in
                        HStack {
                            Text(pr.exercise)
                            Spacer()
                            Text("\(pr.weight) lb × \(pr.reps)")
                                .bold()
                        }
                    }
                }
            }

            Section("Recent Workouts") {
                ForEach(logStore.logs.prefix(5)) { log in
                    NavigationLink {
                        WorkoutLogDetailView(log: log)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(log.workoutName)
                                .font(.headline)

                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(setCount(for: log)) sets")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Analytics")
    }

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
