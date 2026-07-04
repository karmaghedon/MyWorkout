import SwiftUI

struct ExerciseSessionState {
    var reps: Int = 10
    var weight: Int = 0
    var loggedSets: [LoggedSet] = []
    var suggestionMessage: String? = nil
    var notes: String = ""
}

struct WorkoutSessionView: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var settingsStore: UserSettingsStore
    @EnvironmentObject var activeWorkoutStore: ActiveWorkoutStore
    @Environment(\.dismiss) private var dismiss

    @State private var activeRestExerciseID: UUID?
    @State private var restSecondsRemaining = 0
    @State private var restTotalSeconds = 0
    @State private var restTimer: Timer?
    @State private var showFinishSummary = false
    @State private var showLeaveConfirmation = false
    @State private var showCancelConfirmation = false

    private var workout: Workout? {
        activeWorkoutStore.activeWorkout
    }

    var body: some View {
        Group {
            if let workout {
                workoutContent(workout)
            } else {
                ContentUnavailableView(
                    "No Active Workout",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("Start a workout from a template.")
                )
            }
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle(workout?.name ?? "Workout")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationBarBackButtonHidden(activeWorkoutStore.hasLoggedSets)
        .toolbar {
            if activeWorkoutStore.hasLoggedSets {
                ToolbarItem(placement: .navigation) {
                    Button {
                        showLeaveConfirmation = true
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                }
            }
        }
        .onAppear {
            activeWorkoutStore.resumeTimer()
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
        .confirmationDialog(
            "Leave workout?",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Keep Workout Running") {
                dismiss()
            }

            Button("Cancel Workout", role: .destructive) {
                activeWorkoutStore.cancel()
                dismiss()
            }

            Button("Stay Here", role: .cancel) {}
        } message: {
            Text("Your logged sets will remain active if you keep the workout running.")
        }
        .confirmationDialog(
            "Cancel Workout?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Workout", role: .destructive) {
                activeWorkoutStore.cancel()
                dismiss()
            }

            Button("Keep Workout", role: .cancel) {}
        } message: {
            Text("This will discard the current workout and all logged sets.")
        }
    }

    private func workoutContent(_ workout: Workout) -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.lg) {
                workoutTimerCard

                ForEach(workout.exercises) { exercise in
                    ExerciseSessionCardView(
                        exercise: exercise,
                        state: binding(for: exercise.id),
                        previousSets: logStore.lastPerformances(for: exercise, limit: 1).first?.sets ?? [],
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
                .padding(.top, AppTheme.Spacing.lg)

                Button(role: .destructive) {
                    showCancelConfirmation = true
                } label: {
                    Text("Cancel Workout")
                        .font(AppTheme.Typography.label)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .padding(AppTheme.Spacing.lg)
            .animation(.default, value: activeRestExerciseID)
        }
    }

    private var workoutTimerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("WORKOUT TIME")
                    .font(AppTheme.Typography.eyebrow)
                    .foregroundStyle(.secondary)

                Text(activeWorkoutStore.formattedElapsedTime)
                    .font(AppTheme.Typography.numeric(28))
                    .monospacedDigit()
            }

            Spacer()

            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private func initializeStates() {
        guard let workout else { return }

        for exercise in workout.exercises {
            if activeWorkoutStore.exerciseStates[exercise.id] == nil {
                if let latestExercise = logStore.lastPerformances(for: exercise, limit: 1).first,
                   let latestSet = latestExercise.sets.last {

                    let previous = logStore.lastPerformances(
                        for: exercise,
                        limit: exercise.progressionRule.stallLimit
                    )

                    let suggestion = ProgressionEngine.suggestion(
                        exercise: exercise,
                        currentSets: latestExercise.sets,
                        previousPerformances: Array(previous.dropFirst())
                    )

                    activeWorkoutStore.exerciseStates[exercise.id] = ExerciseSessionState(
                        reps: latestSet.reps,
                        weight: suggestion?.suggestedWeight ?? latestSet.weight,
                        loggedSets: [],
                        suggestionMessage: suggestion?.message,
                        notes: ""
                    )
                } else {
                    activeWorkoutStore.exerciseStates[exercise.id] = ExerciseSessionState(
                        reps: 10,
                        weight: defaultStartingWeight(for: exercise),
                        loggedSets: [],
                        suggestionMessage: "No history yet",
                        notes: ""
                    )
                }
            }
        }
    }

    private func defaultStartingWeight(for exercise: Exercise) -> Int {
        switch exercise.exerciseType {
        case .bodyweight:
            return 0
        case .compound, .isolation:
            return exercise.usesBarbell ? Int(equipmentStore.inventory.barbellWeight.rounded()) : 0
        }
    }

    private func logSet(for exerciseID: UUID) {
        var state = activeWorkoutStore.exerciseStates[exerciseID] ?? ExerciseSessionState()

        let newSet = LoggedSet(
            setNumber: state.loggedSets.count + 1,
            weight: state.weight,
            reps: state.reps
        )

        state.loggedSets.append(newSet)
        activeWorkoutStore.exerciseStates[exerciseID] = state

        Haptics.setLogged()
    }

    private func finishWorkout() {
        guard let workout else { return }

        let completedExercises = workout.exercises.compactMap { exercise -> CompletedExercise? in
            guard let state = activeWorkoutStore.exerciseStates[exercise.id],
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

        guard !completedExercises.isEmpty else { return }

        let log = WorkoutLog(
            workoutName: workout.name,
            date: Date(),
            durationSeconds: activeWorkoutStore.currentDurationSeconds(),
            completedExercises: completedExercises
        )

        logStore.add(log)
        activeWorkoutStore.finish()
        dismiss()
    }

    private func binding(for exerciseID: UUID) -> Binding<ExerciseSessionState> {
        Binding(
            get: {
                activeWorkoutStore.exerciseStates[exerciseID] ?? ExerciseSessionState()
            },
            set: {
                activeWorkoutStore.exerciseStates[exerciseID] = $0
            }
        )
    }

    private func startRestTimer(for exercise: Exercise) {
        stopRestTimer()

        activeRestExerciseID = exercise.id
        restTotalSeconds = RestTimerRule.seconds(
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
                Haptics.restComplete()
            }
        }
    }

    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restSecondsRemaining = 0
        activeRestExerciseID = nil
    }

    private func workoutSummaryText() -> String {
        guard let workout else { return "No active workout." }

        let completed = workout.exercises.compactMap { exercise -> String? in
            guard let state = activeWorkoutStore.exerciseStates[exercise.id],
                  !state.loggedSets.isEmpty else {
                return nil
            }

            return "\(exercise.name): \(state.loggedSets.count) set(s)"
        }

        let totalSets = workout.exercises.reduce(0) { total, exercise in
            total + (activeWorkoutStore.exerciseStates[exercise.id]?.loggedSets.count ?? 0)
        }

        return completed.joined(separator: "\n")
            + "\n\nTotal sets: \(totalSets)"
            + "\nDuration: \(activeWorkoutStore.formattedElapsedTime)"
    }

    private func deleteSet(setID: UUID, for exerciseID: UUID) {
        guard var state = activeWorkoutStore.exerciseStates[exerciseID] else { return }

        state.loggedSets.removeAll { $0.id == setID }

        state.loggedSets = state.loggedSets.enumerated().map { index, set in
            LoggedSet(
                setNumber: index + 1,
                weight: set.weight,
                reps: set.reps
            )
        }

        activeWorkoutStore.exerciseStates[exerciseID] = state
    }
}
