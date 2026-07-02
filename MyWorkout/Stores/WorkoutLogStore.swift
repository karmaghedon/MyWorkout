import Foundation

final class WorkoutLogStore: ObservableObject {
    @Published var logs: [WorkoutLog] = []

    private let key = "workout_logs"

    init() {
        load()
    }

    func add(_ log: WorkoutLog) {
        logs.insert(log, at: 0)
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(logs)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save logs: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }

        do {
            logs = try JSONDecoder().decode([WorkoutLog].self, from: data)
        } catch {
            print("Failed to load logs: \(error)")
        }
    }
    
    func lastPerformance(for exerciseName: String) -> LoggedSet? {
        for log in logs {
            for exercise in log.completedExercises {
                if exercise.exerciseName == exerciseName {
                    return exercise.sets.last
                }
            }
        }

        return nil
    }
    
    func lastPerformances(for exerciseName: String, limit: Int) -> [CompletedExercise] {
        var results: [CompletedExercise] = []

        for log in logs {
            for exercise in log.completedExercises {
                if exercise.exerciseName == exerciseName {
                    results.append(exercise)
                }

                if results.count == limit {
                    return results
                }
            }
        }

        return results
    }
    
    func suggestedStartingSet(for exercise: Exercise) -> LoggedSet? {
        guard let latestExercise = lastPerformances(for: exercise.name, limit: 1).first,
              let latestSet = latestExercise.sets.last else {
            return nil
        }

        let previous = lastPerformances(for: exercise.name, limit: exercise.progressionRule.stallLimit)

        guard let suggestion = ProgressionEngine.suggestion(
            exercise: exercise,
            currentSets: latestExercise.sets,
            previousPerformances: Array(previous.dropFirst())
        ) else {
            return latestSet
        }

        return LoggedSet(
            setNumber: 1,
            weight: suggestion.suggestedWeight,
            reps: latestSet.reps
        )
    }
    
    func replaceAll(with newLogs: [WorkoutLog]) {
        logs = newLogs
        save()
    }
}
