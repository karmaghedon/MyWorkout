import SwiftUI

struct ExerciseSessionState {
    var reps: Int = 10
    var weight: Int = 45
    var loggedSets: [LoggedSet] = []
    var suggestionMessage: String? = nil
    var notes: String = ""
}

struct WorkoutSessionView: View {
    let workout: Workout

    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @Environment(\.dismiss) private var dismiss

    @State private var exerciseStates: [UUID: ExerciseSessionState] = [:]
    @State private var activeRestExerciseID: UUID?
    @State private var restSecondsRemaining = 0
    @State private var restTimer: Timer?
    @State private var showFinishSummary = false

    var body: some View {
        VStack {
            List {
                ForEach(workout.exercises) { exercise in
                    Section(exercise.name) {
                        let state = exerciseStates[exercise.id] ?? ExerciseSessionState()

                        if let suggestion = state.suggestionMessage {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        let warmups = WarmupEngine.generateWarmups(
                            for: state.weight,
                            exerciseType: exercise.exerciseType
                        )

                        if !warmups.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Warm-up")
                                    .font(.caption)
                                    .bold()

                                ForEach(warmups) { warmup in
                                    if exercise.usesBarbell {
                                        let loading = PlateCalculator.loading(
                                            for: warmup.weight,
                                            inventory: equipmentStore.inventory
                                        )

                                        Text("\(warmup.weight) lb × \(warmup.reps) — \(loading.displayText) / side")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("\(warmup.weight) lb × \(warmup.reps)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            Text("Reps")
                                .frame(width: 70, alignment: .leading)

                            Stepper("", value: binding(for: exercise.id).reps, in: 1...50)
                                .labelsHidden()

                            TextField("Reps", value: binding(for: exercise.id).reps, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 70)
                        }

                        let weightStep = exercise.usesBarbell
                            ? equipmentStore.smallestPlateIncrement()
                            : 5

                        HStack(spacing: 12) {
                            Text("Weight")
                                .frame(width: 70, alignment: .leading)

                            Stepper(
                                "",
                                value: binding(for: exercise.id).weight,
                                in: 0...500,
                                step: weightStep
                            )
                            .labelsHidden()

                            TextField("Weight", value: binding(for: exercise.id).weight, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)

                            Text("lb")
                        }

                        if exercise.usesBarbell {
                            let workingLoading = PlateCalculator.loading(
                                for: state.weight,
                                inventory: equipmentStore.inventory
                            )

                            Text("Working load: \(workingLoading.displayText) / side")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Button("Log Set") {
                            logSet(for: exercise.id)
                            startRestTimer(for: exercise)
                        }

                        if activeRestExerciseID == exercise.id && restSecondsRemaining > 0 {
                            Text("Rest: \(formatTime(restSecondsRemaining))")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button("Stop Rest Timer") {
                                stopRestTimer()
                            }
                        }

                        ForEach(state.loggedSets) { set in
                            HStack {
                                Text("Set \(set.setNumber): \(set.weight) lb × \(set.reps)")
                                    .font(.caption)

                                Spacer()

                                Button("Delete") {
                                    deleteSet(setID: set.id, for: exercise.id)
                                }
                                .font(.caption)
                            }
                        }

                        Text("Notes")
                            .font(.caption)
                            .bold()

                        TextEditor(text: binding(for: exercise.id).notes)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.gray.opacity(0.4))
                            )
                    }
                }
            }

            Button("Finish Workout") {
                showFinishSummary = true
            }
            .padding()
        }
        .navigationTitle(workout.name)
        .onAppear {
            initializeStates()
        }
        .onDisappear {
            stopRestTimer()
        }
        .confirmationDialog(
            "Finish Workout?",
            isPresented: $showFinishSummary,
            titleVisibility: .visible
        ) {
            Button("Save Workout") {
                finishWorkout()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(workoutSummaryText())
        }
    }

    private func initializeStates() {
        for exercise in workout.exercises {
            if exerciseStates[exercise.id] == nil {
                if let latestExercise = logStore.lastPerformances(for: exercise.name, limit: 1).first,
                   let latestSet = latestExercise.sets.last {

                    let previous = logStore.lastPerformances(
                        for: exercise.name,
                        limit: exercise.progressionRule.stallLimit
                    )

                    let suggestion = ProgressionEngine.suggestion(
                        exercise: exercise,
                        currentSets: latestExercise.sets,
                        previousPerformances: Array(previous.dropFirst())
                    )

                    exerciseStates[exercise.id] = ExerciseSessionState(
                        reps: latestSet.reps,
                        weight: suggestion?.suggestedWeight ?? latestSet.weight,
                        loggedSets: [],
                        suggestionMessage: suggestion?.message,
                        notes: ""
                    )
                } else {
                    exerciseStates[exercise.id] = ExerciseSessionState(
                        suggestionMessage: "No history yet"
                    )
                }
            }
        }
    }

    private func logSet(for exerciseID: UUID) {
        var state = exerciseStates[exerciseID] ?? ExerciseSessionState()

        let newSet = LoggedSet(
            setNumber: state.loggedSets.count + 1,
            weight: state.weight,
            reps: state.reps
        )

        state.loggedSets.append(newSet)
        exerciseStates[exerciseID] = state
    }

    private func finishWorkout() {
        let completedExercises = workout.exercises.compactMap { exercise -> CompletedExercise? in
            guard let state = exerciseStates[exercise.id],
                  !state.loggedSets.isEmpty else {
                return nil
            }

            return CompletedExercise(
                exerciseName: exercise.name,
                sets: state.loggedSets,
                notes: state.notes
            )
        }

        guard !completedExercises.isEmpty else { return }

        let log = WorkoutLog(
            workoutName: workout.name,
            date: Date(),
            completedExercises: completedExercises
        )

        logStore.add(log)
        dismiss()
    }

    private func binding(for exerciseID: UUID) -> Binding<ExerciseSessionState> {
        Binding(
            get: {
                exerciseStates[exerciseID] ?? ExerciseSessionState()
            },
            set: {
                exerciseStates[exerciseID] = $0
            }
        )
    }

    private func startRestTimer(for exercise: Exercise) {
        stopRestTimer()

        activeRestExerciseID = exercise.id
        restSecondsRemaining = RestTimerRule.seconds(for: exercise.exerciseType)

        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if restSecondsRemaining > 0 {
                restSecondsRemaining -= 1
            } else {
                timer.invalidate()
                restTimer = nil
                activeRestExerciseID = nil
            }
        }
    }

    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        activeRestExerciseID = nil
        restSecondsRemaining = 0
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func workoutSummaryText() -> String {
        let completed = workout.exercises.compactMap { exercise -> String? in
            guard let state = exerciseStates[exercise.id],
                  !state.loggedSets.isEmpty else {
                return nil
            }

            return "\(exercise.name): \(state.loggedSets.count) set(s)"
        }

        let totalSets = workout.exercises.reduce(0) { total, exercise in
            total + (exerciseStates[exercise.id]?.loggedSets.count ?? 0)
        }

        return completed.joined(separator: "\n") + "\n\nTotal sets: \(totalSets)"
    }

    private func deleteSet(setID: UUID, for exerciseID: UUID) {
        guard var state = exerciseStates[exerciseID] else { return }

        state.loggedSets.removeAll { $0.id == setID }

        state.loggedSets = state.loggedSets.enumerated().map { index, set in
            LoggedSet(
                setNumber: index + 1,
                weight: set.weight,
                reps: set.reps
            )
        }

        exerciseStates[exerciseID] = state
    }
}
