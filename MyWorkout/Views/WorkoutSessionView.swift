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
    @EnvironmentObject var settingsStore: UserSettingsStore

    @State private var exerciseStates: [UUID: ExerciseSessionState] = [:]
    @State private var activeRestExerciseID: UUID?
    @State private var restSecondsRemaining = 0
    @State private var restTotalSeconds = 0
    @State private var restTimer: Timer?
    @State private var showFinishSummary = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.lg) {
                    ForEach(workout.exercises) { exercise in
                        ExerciseSessionCardView(
                            exercise: exercise,
                            state: binding(for: exercise.id),
                            weightStep: exercise.usesBarbell
                                ? equipmentStore.smallestPlateIncrement()
                                : 5,
                            equipmentInventory: equipmentStore.inventory,
                            isResting: activeRestExerciseID == exercise.id && restSecondsRemaining > 0,
                            restSecondsRemaining: restSecondsRemaining,
                            restTotalSeconds: restTotalSeconds,
                            onLogSet: {
                                logSet(for: exercise.id)
                                startRestTimer(for: exercise)
                            },
                            onStopRest: stopRestTimer,
                            onDeleteSet: { setID in
                                deleteSet(setID: setID, for: exercise.id)
                            }
                        )
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .animation(.default, value: activeRestExerciseID)
            }
            .background(AppTheme.groupedBackground)

            Divider()

            Button {
                showFinishSummary = true
            } label: {
                Text("Finish Workout")
                    .font(AppTheme.Typography.label)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
            .padding(AppTheme.Spacing.lg)
            .background(.bar)
        }
        .navigationTitle(workout.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
        restSecondsRemaining = RestTimerRule.seconds(
            for: exercise.exerciseType,
            settings: settingsStore.settings
        )
        restSecondsRemaining = restTotalSeconds

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
