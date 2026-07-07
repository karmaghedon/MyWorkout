import Foundation

@MainActor
final class WorkoutLogStore: ObservableObject {
    @Published var logs: [WorkoutLog] = []

    @Published private(set) var lastSaveError: String?

    private let legacyDefaultsKey = "workout_logs"

    private let fileURL: URL
    private let saveQueue = DispatchQueue(label: "com.myworkout.workoutlogstore.save", qos: .utility)

    init() {
        fileURL = Self.resolveFileURL()
        load()
    }

    func add(_ log: WorkoutLog) {
        logs.insert(log, at: 0)
        save()
    }

    func replaceAll(with newLogs: [WorkoutLog]) {
        logs = newLogs
        save()
    }

    func lastPerformance(for exercise: Exercise) -> LoggedSet? {
        for log in logs {
            for completedExercise in log.completedExercises {
                if matches(completedExercise, exercise: exercise) {
                    return completedExercise.sets.last
                }
            }
        }

        return nil
    }

    func lastPerformances(for exercise: Exercise, limit: Int) -> [CompletedExercise] {
        var results: [CompletedExercise] = []

        for log in logs {
            for completedExercise in log.completedExercises {
                if matches(completedExercise, exercise: exercise) {
                    results.append(completedExercise)
                }

                if results.count == limit {
                    return results
                }
            }
        }

        return results
    }

    func suggestedStartingSet(for exercise: Exercise) -> LoggedSet? {
        guard let latestExercise = lastPerformances(for: exercise, limit: 1).first,
              let latestSet = latestExercise.sets.last else {
            return nil
        }

        let previous = lastPerformances(
            for: exercise,
            limit: exercise.progressionRule.stallLimit
        )

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

    private func matches(_ completedExercise: CompletedExercise, exercise: Exercise) -> Bool {
        if let exerciseID = completedExercise.exerciseID {
            return exerciseID == exercise.id
        }

        // Backward compatibility for old logs saved before exerciseID existed.
        return completedExercise.exerciseName == exercise.name
    }

    // MARK: - Persistence

    private static func resolveFileURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("MyWorkout", isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory.appendingPathComponent("workout_logs.json")
    }

    private func save() {
        let logsToSave = logs
        let destination = fileURL

        saveQueue.async { [weak self] in
            do {
                let data = try JSONEncoder().encode(logsToSave)
                try data.write(to: destination, options: .atomic)

                DispatchQueue.main.async {
                    self?.lastSaveError = nil
                }
            } catch {
                print("Failed to save workout logs: \(error)")

                DispatchQueue.main.async {
                    self?.lastSaveError = "Couldn't save your latest workout. Please try again."
                }
            }
        }
    }

    private func load() {
        if !FileManager.default.fileExists(atPath: fileURL.path),
           let legacyData = UserDefaults.standard.data(forKey: legacyDefaultsKey) {
            if let decoded = try? JSONDecoder().decode([WorkoutLog].self, from: legacyData) {
                logs = decoded
                save()
            }

            UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
            return
        }

        guard let data = try? Data(contentsOf: fileURL) else { return }

        do {
            logs = try JSONDecoder().decode([WorkoutLog].self, from: data)
        } catch {
            print("Failed to load workout logs: \(error)")
            lastSaveError = "Couldn't load your saved workouts. Recent data may be unavailable."
        }
    }
}
