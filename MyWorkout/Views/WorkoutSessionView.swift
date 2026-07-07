import SwiftUI

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
                NoActiveWorkoutView()
            }
        }
        .background(AppTheme.groupedBackground)
        .dismissKeyboardOnTap()
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
            if let workout {
                activeWorkoutStore.initializeExerciseStates(
                    for: workout,
                    logStore: logStore,
                    equipmentInventory: equipmentStore.inventory
                )
            }
        }
        .onDisappear {
            // Keep rest timer running in ActiveWorkoutStore
        }
        .workoutSessionDialogs(
            showFinishSummary: $showFinishSummary,
            showLeaveConfirmation: $showLeaveConfirmation,
            showCancelConfirmation: $showCancelConfirmation,
            summaryText: WorkoutSessionEngine.summaryText(
                workout: workout,
                states: activeWorkoutStore.exerciseStates,
                formattedElapsedTime: activeWorkoutStore.formattedElapsedTime
            ),
            onFinish: finishWorkout,
            onKeepWorkoutRunning: {
                dismiss()
            },
            onCancelWorkout: {
                activeWorkoutStore.cancel()
                dismiss()
            }
        )
    }

    private func workoutContent(_ workout: Workout) -> some View {
        WorkoutSessionContentView(
            workout: workout,
            elapsedTime: activeWorkoutStore.formattedElapsedTime,
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
                activeWorkoutStore.logSet(for: exercise.id)
                Haptics.setLogged()
                activeWorkoutStore.startRestTimer(
                    for: exercise,
                    settings: settingsStore.settings
                )
            },
            onStopRest: {
                activeWorkoutStore.stopRestTimer()
            },
            onDeleteSet: { setID, exercise in
                activeWorkoutStore.deleteSet(setID: setID, for: exercise.id)
            },
            onFinish: {
                showFinishSummary = true
            },
            onCancel: {
                showCancelConfirmation = true
            }
        )
    }

    private func finishWorkout() {
        guard let workout else { return }

        guard let log = WorkoutSessionEngine.workoutLog(
            for: workout,
            states: activeWorkoutStore.exerciseStates,
            durationSeconds: activeWorkoutStore.currentDurationSeconds()
        ) else {
            return
        }

        logStore.add(log)
        activeWorkoutStore.finish()
        dismiss()
    }
}
