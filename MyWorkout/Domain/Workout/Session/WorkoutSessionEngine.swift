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

    /// Whether logging a set for `exercise` should start the rest timer.
    ///
    /// Ungrouped exercises always rest after every set — unchanged
    /// behavior. A superset/circuit (exercises sharing a
    /// `supersetGroupID`) is meant to be performed back-to-back with no
    /// rest between members, resting only once every *active* member
    /// (see `activeGroupMembers`) has logged one set for the round —
    /// detected as the total sets logged across active members landing
    /// on an exact multiple of how many active members there are, right
    /// after this log. That's equivalent to "this log was the last turn
    /// in the rotation," without needing separate round-tracking state.
    ///
    /// This used to be a purely positional check ("is `exercise` last in
    /// `workout.exercises`"), which broke once `canLogNextSet` allowed a
    /// tied round to be completed by *either* member: an exercise ahead
    /// of its sibling could still be the one to trigger rest merely by
    /// occupying the last array slot, or the sibling catching up could
    /// spuriously "complete a round" that was never actually run in
    /// strict turn order. Tying this to the same active-member/rotation
    /// accounting `canLogNextSet` uses keeps the two in lockstep: once
    /// logging is turn-gated, rest only fires when a turn was genuinely
    /// the round's last.
    static func shouldStartRest(
        after exercise: Exercise,
        in workout: Workout,
        states: [UUID: ExerciseSessionState]
    ) -> Bool {
        guard let groupID = exercise.supersetGroupID else {
            return true
        }

        let groupMembers = workout.exercises.filter { $0.supersetGroupID == groupID }

        // `exercise` counts as active here even if the set just logged
        // brought it to its own `targetSets` — it was still part of this
        // round's rotation, so it belongs in the round-completion count.
        let activeMembers = groupMembers.filter {
            (states[$0.id]?.loggedSets.count ?? 0) < $0.targetSets
                || $0.id == exercise.id
        }

        guard !activeMembers.isEmpty else {
            return true
        }

        let totalLogged = activeMembers.reduce(0) {
            $0 + (states[$1.id]?.loggedSets.count ?? 0)
        }

        return totalLogged % activeMembers.count == 0
    }

    /// Which exercise's card the rest-timer badge should attach to once
    /// rest actually starts (see `shouldStartRest` — that's only once the
    /// group's last member logs its set for the round). Rest between
    /// superset rounds is "time until you start the round again," and the
    /// round restarts at the group's *first* exercise, not its last — so
    /// anchoring the badge there keeps the countdown where the user's
    /// attention returns to, instead of trailing the exercise they just
    /// finished and won't touch again until it ends. Ungrouped exercises
    /// are unaffected: the badge stays on the exercise itself.
    static func restTimerAnchorExerciseID(
        for exercise: Exercise,
        in workout: Workout?
    ) -> UUID {
        guard let groupID = exercise.supersetGroupID,
              let workout,
              let firstGroupMemberID = workout.exercises
                  .filter({ $0.supersetGroupID == groupID })
                  .first?.id
        else {
            return exercise.id
        }

        return firstGroupMemberID
    }

    /// The group members (in workout order) that still have sets left to
    /// log — a member that already logged all of its own `targetSets` is
    /// excluded entirely, not just capped at its final count. Group
    /// members don't have to share the same `targetSets`: without this
    /// exclusion, a member with fewer sets than its partner would freeze
    /// at its final count forever once finished, permanently blocking the
    /// partner from its own remaining sets.
    private static func activeGroupMembers(
        for groupID: UUID,
        in exercises: [Exercise],
        states: [UUID: ExerciseSessionState]
    ) -> [Exercise] {
        exercises.filter {
            $0.supersetGroupID == groupID
                && (states[$0.id]?.loggedSets.count ?? 0) < $0.targetSets
        }
    }

    /// Whose turn it is to log next among a group's still-active members,
    /// enforcing *strict* rotation — `exercises[0]` logs, then
    /// `exercises[1]`, and so on back to `exercises[0]` — rather than just
    /// "whoever's tied may go." A tie alone used to let either member go
    /// next, which meant a member could take two turns in a row (get one
    /// set ahead) purely because nothing had forced the other member's
    /// turn first — and that "getting ahead" is exactly what let a
    /// sibling's later catch-up set look like it completed a round when
    /// it hadn't actually been run in alternating order (see
    /// `shouldStartRest`). Turn order is derived from the total sets
    /// logged across active members so far, cycled through them in
    /// `exercises` order — no separate "whose turn" state to persist.
    private static func activeMemberWhoseTurnItIs(
        among activeMembers: [Exercise],
        states: [UUID: ExerciseSessionState]
    ) -> Exercise? {
        guard !activeMembers.isEmpty else { return nil }

        let totalLogged = activeMembers.reduce(0) {
            $0 + (states[$1.id]?.loggedSets.count ?? 0)
        }

        return activeMembers[totalLogged % activeMembers.count]
    }

    /// Whether `exercise` may log another set right now. Ungrouped
    /// exercises can always proceed — unchanged behavior. A superset/
    /// circuit is meant to be worked in strict rotation: every member logs
    /// its set 1, in order, before anyone logs set 2, and so on — see
    /// `activeMemberWhoseTurnItIs`. `exercise` may proceed only if it's
    /// already finished (nothing left to gate) or it's genuinely its turn.
    static func canLogNextSet(
        for exercise: Exercise,
        in exercises: [Exercise],
        states: [UUID: ExerciseSessionState]
    ) -> Bool {
        guard let groupID = exercise.supersetGroupID else { return true }

        let activeMembers = activeGroupMembers(
            for: groupID,
            in: exercises,
            states: states
        )

        guard activeMembers.contains(where: { $0.id == exercise.id }) else {
            // Already finished its own targetSets — nothing left to gate.
            return true
        }

        return activeMemberWhoseTurnItIs(
            among: activeMembers,
            states: states
        )?.id == exercise.id
    }

    /// The group member whose turn it currently is, when `exercise` is
    /// the one being held back by `canLogNextSet`. `nil` when `exercise`
    /// isn't blocked or isn't part of a group, so callers can use this
    /// directly to decide whether to show a "move to the next exercise"
    /// hint. A sibling that has already finished all of its own
    /// `targetSets` is never returned here — same reasoning as
    /// `canLogNextSet`: a finished member isn't holding anything back, so
    /// pointing the user at it would be a confusing dead end.
    static func nextSupersetExercise(
        after exercise: Exercise,
        in exercises: [Exercise],
        states: [UUID: ExerciseSessionState]
    ) -> Exercise? {
        guard let groupID = exercise.supersetGroupID else { return nil }

        guard !canLogNextSet(for: exercise, in: exercises, states: states) else {
            return nil
        }

        let activeMembers = activeGroupMembers(
            for: groupID,
            in: exercises,
            states: states
        )

        return activeMemberWhoseTurnItIs(among: activeMembers, states: states)
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
