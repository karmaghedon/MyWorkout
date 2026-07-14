import Foundation

@MainActor
final class WorkoutLogStore: ObservableObject {
    @Published var logs: [WorkoutLog] = []

    @Published private(set) var persistenceError: StoreError?

    private let repository: any WorkoutLogRepository

    private let saveQueue = DispatchQueue(
        label: "com.myworkout.workoutlogstore.save",
        qos: .utility
    )

    /// Prevents unreadable persisted history from being overwritten.
    private var isPersistenceWritable = true

    init(
        repository: any WorkoutLogRepository =
            FileWorkoutLogRepository()
    ) {
        self.repository = repository
        load()
    }

    // MARK: - Log Actions

    func add(_ log: WorkoutLog) {
        logs.insert(log, at: 0)
        save()
    }

    func replaceAll(
        with newLogs: [WorkoutLog]
    ) {
        logs = newLogs
        save()
    }

    // MARK: - Performance Queries

    func lastPerformance(
        for exercise: Exercise
    ) -> LoggedSet? {
        for log in logs {
            for completedExercise in log.completedExercises {
                if matches(
                    completedExercise,
                    exercise: exercise
                ) {
                    return completedExercise.sets.last
                }
            }
        }

        return nil
    }

    func lastPerformances(
        for exercise: Exercise,
        limit: Int
    ) -> [CompletedExercise] {
        var results: [CompletedExercise] = []

        for log in logs {
            for completedExercise in log.completedExercises {
                if matches(
                    completedExercise,
                    exercise: exercise
                ) {
                    results.append(completedExercise)
                }

                if results.count == limit {
                    return results
                }
            }
        }

        return results
    }

    func suggestedStartingSet(
        for exercise: Exercise
    ) -> LoggedSet? {
        guard let latestExercise = lastPerformances(
            for: exercise,
            limit: 1
        ).first,
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
            previousPerformances: Array(
                previous.dropFirst()
            )
        ) else {
            return latestSet
        }

        return LoggedSet(
            setNumber: 1,
            weight: suggestion.suggestedWeight,
            reps: latestSet.reps
        )
    }

    private func matches(
        _ completedExercise: CompletedExercise,
        exercise: Exercise
    ) -> Bool {
        if let exerciseID = completedExercise.exerciseID {
            return exerciseID == exercise.id
        }

        // Backward compatibility for historical logs
        // saved before exerciseID existed.
        return completedExercise.exerciseName == exercise.name
    }

    // MARK: - Persistence Errors

    func clearPersistenceError() {
        persistenceError = nil
    }

    private func setPersistenceError(
        operation: StoreOperation,
        message: String
    ) {
        persistenceError = StoreError(
            operation: operation,
            message: message
        )
    }

    private func clearPersistenceError(
        for operation: StoreOperation
    ) {
        guard persistenceError?.operation == operation else {
            return
        }

        persistenceError = nil
    }

    // MARK: - Persistence

    private func load() {
        do {
            logs = try repository.load()
            isPersistenceWritable = true

            clearPersistenceError(
                for: .loading
            )
        } catch {
            isPersistenceWritable = false

            print(
                "Failed to load workout logs: \(error)"
            )

            setPersistenceError(
                operation: .loading,
                message:
                    "Couldn't load your saved workouts. "
                    + "The existing history was preserved "
                    + "and will not be overwritten."
            )
        }
    }

    private func save() {
        guard isPersistenceWritable else {
            setPersistenceError(
                operation: .saving,
                message:
                    "Your workout history could not be read, "
                    + "so it was not overwritten. Restart the app "
                    + "or restore a valid backup before saving "
                    + "more workouts."
            )

            return
        }

        /*
         Capture an immutable snapshot while on MainActor.

         This prevents the background save from reading the
         @Published collection while it is being modified.
         */
        let logsToSave = logs
        let repository = repository

        saveQueue.async { [weak self] in
            do {
                try repository.save(logsToSave)

                DispatchQueue.main.async {
                    self?.clearPersistenceError(
                        for: .saving
                    )
                }
            } catch {
                print(
                    "Failed to save workout logs: \(error)"
                )

                DispatchQueue.main.async {
                    self?.setPersistenceError(
                        operation: .saving,
                        message:
                            "Couldn't save your latest workout. "
                            + "Please try again."
                    )
                }
            }
        }
    }
}
