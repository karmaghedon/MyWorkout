import Foundation

enum WorkoutSessionEngine {
    
    static func makeLoggedSet(
        from state: ExerciseSessionState
    ) -> LoggedSet {
        let validatedWeight = InputValidation.clampWeight(
            state.workingWeightPounds
        )

        let validatedReps = InputValidation.clampReps(
            state.targetReps
        )

        return LoggedSet(
            setNumber: state.loggedSets.count + 1,
            weight: validatedWeight,
            reps: validatedReps
        )
    }

    static func defaultStartingWeight(
        for exercise: Exercise,
        equipmentInventory: EquipmentInventory
    ) -> Double {
        switch exercise.exerciseType {
        case .bodyweight:
            return 0

        case .compound, .isolation:
            guard exercise.usesBarbell else {
                return 0
            }

            return WeightConversion.toPounds(
                equipmentInventory.barbellWeight,
                from: equipmentInventory.unitSystem
            )
        }
    }

    static func logSet(
        for exerciseID: UUID,
        in states: inout [UUID: ExerciseSessionState]
    ) {
        var state = states[exerciseID] ?? ExerciseSessionState()

        let loggedSet = makeLoggedSet(
            from: state
        )

        state.loggedSets.append(loggedSet)

        state.workingWeightPounds = loggedSet.weight
        state.targetReps = loggedSet.reps

        states[exerciseID] = state
    }

    static func deleteSet(
        setID: UUID,
        for exerciseID: UUID,
        in states: inout [UUID: ExerciseSessionState]
    ) {
        guard var state = states[exerciseID] else { return }

        state.loggedSets.removeAll { $0.id == setID }

        state.loggedSets = state.loggedSets.enumerated().map { index, set in
            LoggedSet(
                setNumber: index + 1,
                weight: set.weight,
                reps: set.reps
            )
        }

        states[exerciseID] = state
    }

    static func summaryText(
        workout: Workout?,
        states: [UUID: ExerciseSessionState],
        formattedElapsedTime: String
    ) -> String {
        guard let workout else {
            return "No active workout."
        }

        let completed = workout.exercises.compactMap { exercise -> String? in
            guard let state = states[exercise.id],
                  !state.loggedSets.isEmpty else {
                return nil
            }

            return "\(exercise.name): \(state.loggedSets.count) set(s)"
        }

        let totalSets = workout.exercises.reduce(0) { total, exercise in
            total + (states[exercise.id]?.loggedSets.count ?? 0)
        }

        return completed.joined(separator: "\n")
            + "\n\nTotal sets: \(totalSets)"
            + "\nDuration: \(formattedElapsedTime)"
    }

    static func completedExercises(
        for workout: Workout,
        states: [UUID: ExerciseSessionState]
    ) -> [CompletedExercise] {
        workout.exercises.compactMap { exercise in
            guard let state = states[exercise.id],
                  !state.loggedSets.isEmpty else {
                return nil
            }

            return CompletedExercise(
                exerciseID: exercise.id,
                exerciseName: exercise.name,
                sets: state.loggedSets,
                notes: state.notes
            )
        }
    }

    static func initialState(
        for exercise: Exercise,
        latestPerformance: CompletedExercise?,
        previousPerformances: [CompletedExercise],
        equipmentInventory: EquipmentInventory
    ) -> ExerciseSessionState {
        if let latestPerformance,
           let latestSet = latestPerformance.sets.last {

            let suggestion = ProgressionEngine.suggestion(
                exercise: exercise,
                currentSets: latestPerformance.sets,
                previousPerformances: previousPerformances
            )

            return ExerciseSessionState(
                targetReps: latestSet.reps,
                workingWeightPounds:
                    suggestion?.suggestedWeight ?? latestSet.weight,
                loggedSets: [],
                suggestionMessage: suggestion?.message,
                notes: ""
            )
        }

        return ExerciseSessionState(
            targetReps: 10,
            workingWeightPounds: exercise.targetWeightPounds ?? defaultStartingWeight(
                for: exercise,
                equipmentInventory: equipmentInventory
            ),
            loggedSets: [],
            suggestionMessage: "No history yet",
            notes: ""
        )
    }

    /// Creates a completed workout log from the current session state.
    ///
    /// Returns nil when the session contains no logged sets.
    static func makeCompletedWorkoutLog(
        for workout: Workout,
        states: [UUID: ExerciseSessionState],
        durationSeconds: Int,
        completedAt date: Date = Date()
    ) -> WorkoutLog? {
        let exercises = completedExercises(
            for: workout,
            states: states
        )

        guard !exercises.isEmpty else {
            return nil
        }

        return WorkoutLog(
            workoutName: workout.name,
            date: date,
            durationSeconds: max(0, durationSeconds),
            completedExercises: exercises
        )
    }
    
    /// Compatibility wrapper retained while existing callers are migrated.
    static func workoutLog(
        for workout: Workout,
        states: [UUID: ExerciseSessionState],
        durationSeconds: Int,
        date: Date = Date()
    ) -> WorkoutLog? {
        makeCompletedWorkoutLog(
            for: workout,
            states: states,
            durationSeconds: durationSeconds,
            completedAt: date
        )
    }

    // MARK: - Finish Summary

    /// Total volume (weight × reps, summed across every set) in a log.
    static func totalVolume(in log: WorkoutLog) -> Double {
        log.completedExercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + $1.weight * Double($1.reps) }
        }
    }

    /// Personal records set *by this specific log*, compared against the
    /// best set for each exercise across `priorLogs` only. Computed
    /// directly rather than via `AnalyticsCache` — that cache recomputes
    /// on a 300ms debounce, so reading it immediately after finishing a
    /// workout would show stale (pre-finish) data.
    static func newPersonalRecords(
        in log: WorkoutLog,
        priorLogs: [WorkoutLog]
    ) -> [PersonalRecord] {
        var priorBest: [String: LoggedSet] = [:]

        for priorLog in priorLogs {
            for exercise in priorLog.completedExercises {
                // Same reasoning as `AnalyticsEngine.personalRecords`:
                // `Exercise.id` is launch-stable for both custom exercises
                // (persisted) and built-ins (deterministic hash of the
                // name, see `SeedData.stableID`), and keying by id keeps a
                // renamed custom exercise's history attached to it instead
                // of orphaning it under the old name.
                let key = exercise.exerciseID?.uuidString ?? exercise.exerciseName

                for set in exercise.sets {
                    if let current = priorBest[key] {
                        if isBetterSet(set, than: current) {
                            priorBest[key] = set
                        }
                    } else {
                        priorBest[key] = set
                    }
                }
            }
        }

        var newRecords: [PersonalRecord] = []

        for exercise in log.completedExercises {
            let key = exercise.exerciseID?.uuidString ?? exercise.exerciseName

            guard let bestSetThisSession = exercise.sets.max(
                by: { isBetterSet($1, than: $0) }
            ) else {
                continue
            }

            let isNewRecord: Bool
            if let priorBestSet = priorBest[key] {
                isNewRecord = isBetterSet(bestSetThisSession, than: priorBestSet)
            } else {
                isNewRecord = true
            }

            if isNewRecord {
                newRecords.append(
                    PersonalRecord(
                        exerciseID: exercise.exerciseID,
                        exerciseName: exercise.exerciseName,
                        weightPounds: bestSetThisSession.weight,
                        reps: bestSetThisSession.reps
                    )
                )
            }
        }

        return newRecords
    }

    /// Matches `AnalyticsEngine`'s private comparison: heavier wins;
    /// equal weight falls back to more reps.
    private static func isBetterSet(
        _ newSet: LoggedSet,
        than oldSet: LoggedSet
    ) -> Bool {
        if newSet.weight != oldSet.weight {
            return newSet.weight > oldSet.weight
        }

        return newSet.reps > oldSet.reps
    }
}
