import Foundation

final class WorkoutLogStore: ObservableObject {
    @Published var logs: [WorkoutLog] = []

    /// Set whenever a save or load fails, so views can surface it to the
    /// user instead of silently losing data. Cleared automatically on the
    /// next successful save.
    @Published private(set) var lastSaveError: String?

    /// Legacy UserDefaults key, kept only to migrate existing installs onto
    /// file-based storage on first launch after the upgrade.
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

    /// Writes happen on a background queue so encoding/disk I/O never blocks
    /// the main thread (e.g. mid-workout when a set is logged). The array is
    /// snapshotted synchronously first so we always persist exactly what was
    /// on screen at the time of the call, even if `logs` changes again before
    /// the write completes.
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
        // One-time migration: if no file exists yet but there's data under
        // the old UserDefaults key, adopt it, write it to the new file, and
        // remove the old key so this only runs once.
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
