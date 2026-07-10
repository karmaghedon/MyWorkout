import Foundation

enum WorkoutSessionEngine {

    static func defaultStartingWeight(
        for exercise: Exercise,
        equipmentInventory: EquipmentInventory
    ) -> Double {
        switch exercise.exerciseType {
        case .bodyweight:
            return 0

        case .compound, .isolation:
            return exercise.usesBarbell
                ? equipmentInventory.barbellWeight
                : 0
        }
    }

    static func logSet(
        for exerciseID: UUID,
        in states: inout [UUID: ExerciseSessionState]
    ) {
        var state = states[exerciseID] ?? ExerciseSessionState()

        let validWeight = InputValidation.clampWeight(
            state.workingWeightPounds
        )
        let validReps = InputValidation.clampReps(state.targetReps)

        let newSet = LoggedSet(
            setNumber: state.loggedSets.count + 1,
            weight: validWeight,
            reps: validReps
        )

        state.loggedSets.append(newSet)

        state.workingWeightPounds = validWeight
        state.targetReps = validReps

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
            workingWeightPounds: defaultStartingWeight(
                for: exercise,
                equipmentInventory: equipmentInventory
            ),
            loggedSets: [],
            suggestionMessage: "No history yet",
            notes: ""
        )
    }

    static func workoutLog(
        for workout: Workout,
        states: [UUID: ExerciseSessionState],
        durationSeconds: Int,
        date: Date = Date()
    ) -> WorkoutLog? {
        let completedExercises = completedExercises(
            for: workout,
            states: states
        )

        guard !completedExercises.isEmpty else {
            return nil
        }

        return WorkoutLog(
            workoutName: workout.name,
            date: date,
            durationSeconds: durationSeconds,
            completedExercises: completedExercises
        )
    }
}
