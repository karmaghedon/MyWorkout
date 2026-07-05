import SwiftUI

struct ExerciseSessionState: Codable {
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
            // Keep rest timer running in ActiveWorkoutStore
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
                WorkoutTimerCardView(
                    elapsedTime: activeWorkoutStore.formattedElapsedTime
                )

                WorkoutExerciseListView(
                    exercises: workout.exercises,
                    stateForExercise: { exerciseID in
                        activeWorkoutStore.binding(for: exerciseID)
                    },
                    previousSetsForExercise: { exercise in
                        logStore.lastPerformances(for: exercise, limit: 1).first?.sets ?? []
                    },
                    weightStepForExercise: { exercise in
                        exercise.usesBarbell ? equipmentStore.smallestPlateIncrement() : 5
                    },
                    equipmentInventory: equipmentStore.inventory,
                    activeRestExerciseID: activeWorkoutStore.activeRestExerciseID,
                    restSecondsRemaining: activeWorkoutStore.restSecondsRemaining,
                    restTotalSeconds: activeWorkoutStore.restTotalSeconds,
                    onLogSet: { exercise in
                        logSet(for: exercise.id)
                        startRestTimer(for: exercise)
                    },
                    onStopRest: stopRestTimer,
                    onDeleteSet: { setID, exercise in
                        deleteSet(setID: setID, for: exercise.id)
                    }
                )

                WorkoutSessionActionsView(
                    onFinish: {
                        showFinishSummary = true
                    },
                    onCancel: {
                        showCancelConfirmation = true
                    }
                )
            }
            .padding(AppTheme.Spacing.lg)
            .animation(.default, value: activeWorkoutStore.activeRestExerciseID)
        }
    }

    private func initializeStates() {
        guard let workout else { return }

        for exercise in workout.exercises {
            if activeWorkoutStore.exerciseStates[exercise.id] == nil {
                let performances = logStore.lastPerformances(
                    for: exercise,
                    limit: exercise.progressionRule.stallLimit
                )

                activeWorkoutStore.exerciseStates[exercise.id] = WorkoutSessionEngine.initialState(
                    for: exercise,
                    latestPerformance: performances.first,
                    previousPerformances: Array(performances.dropFirst()),
                    equipmentInventory: equipmentStore.inventory
                )
            }
        }
    }

    private func logSet(for exerciseID: UUID) {
        WorkoutSessionEngine.logSet(
            for: exerciseID,
            in: &activeWorkoutStore.exerciseStates
        )

        Haptics.setLogged()
    }

    private func finishWorkout() {
        guard let workout else { return }

        let completedExercises = WorkoutSessionEngine.completedExercises(
            for: workout,
            states: activeWorkoutStore.exerciseStates
        )

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

    private func startRestTimer(for exercise: Exercise) {
        activeWorkoutStore.startRestTimer(
            for: exercise,
            settings: settingsStore.settings
        )
    }

    private func stopRestTimer() {
        activeWorkoutStore.stopRestTimer()
    }

    private func workoutSummaryText() -> String {
        WorkoutSessionEngine.summaryText(
            workout: workout,
            states: activeWorkoutStore.exerciseStates,
            formattedElapsedTime: activeWorkoutStore.formattedElapsedTime
        )
    }

    private func deleteSet(setID: UUID, for exerciseID: UUID) {
        WorkoutSessionEngine.deleteSet(
            setID: setID,
            for: exerciseID,
            in: &activeWorkoutStore.exerciseStates
        )
    }
}
