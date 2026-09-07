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

    /// `logs` is a load-bearing invariant across the app — `add(_:)`
    /// maintains it by always inserting at index 0, and dozens of call
    /// sites (`logStore.logs.first`, `.prefix(3)`, `lastPerformances`,
    /// `suggestedStartingSet`) read the array assuming newest-first order
    /// without re-sorting themselves. `replaceAll` is the one path that
    /// accepts a caller-supplied order wholesale (backup restore), so it
    /// has to enforce the invariant explicitly rather than trust the
    /// input — a backup built from a source that wasn't already
    /// newest-first (e.g. a chronological CSV export) would otherwise
    /// silently make every "latest performance" lookup return the
    /// *oldest* matching set instead.
    func replaceAll(
        with newLogs: [WorkoutLog]
    ) {
        logs = newLogs.sorted { $0.date > $1.date }
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
            // Defensive re-sort, same reasoning as `replaceAll` — normalizes
            // any on-disk file that predates that fix (or was otherwise
            // written out of order) back to the newest-first invariant.
            logs = try repository.load()
                .sorted { $0.date > $1.date }
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

    /// Blocks until any save already queued by `save()` has actually
    /// finished writing to disk — call when the app is about to
    /// background or terminate, since `save()`'s dispatch to
    /// `saveQueue` is not otherwise guaranteed to complete before the
    /// process is suspended or killed.
    func flushPendingSave() {
        saveQueue.sync {}
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
