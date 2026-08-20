import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct WorkoutSessionView: View {
    @EnvironmentObject var logStore: WorkoutLogStore
    @EnvironmentObject var equipmentStore: EquipmentInventoryStore
    @EnvironmentObject var settingsStore: UserSettingsStore
    @EnvironmentObject var activeWorkoutStore: ActiveWorkoutStore
    @Environment(\.dismiss) private var dismiss

    @State private var showFinishSummary = false
    @State private var showLeaveConfirmation = false
    @State private var showCancelConfirmation = false
    @State private var completedWorkout: CompletedWorkout?

    private struct CompletedWorkout: Identifiable {
        let id = UUID()
        let log: WorkoutLog
        let previousLog: WorkoutLog?
        let newPersonalRecords: [PersonalRecord]
    }

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
        .navigationBarTitleDisplayMode(.inline)
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
            // Keep the screen from auto-locking during an active workout —
            // the user needs it readable between sets without repeatedly
            // waking the phone.
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
        }
        .onDisappear {
            // Keep rest timer running in ActiveWorkoutStore
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
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
        .fullScreenCover(item: $completedWorkout) { completed in
            NavigationStack {
                WorkoutFinishSummaryView(
                    log: completed.log,
                    previousLog: completed.previousLog,
                    newPersonalRecords: completed.newPersonalRecords,
                    onDone: {
                        completedWorkout = nil
                        dismiss()
                    }
                )
            }
        }
    }

    private func workoutContent(_ workout: Workout) -> some View {
        WorkoutSessionContentView(
            workout: workout,
            layout: settingsStore.settings.workoutSessionLayout,
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
            onToggleWarmup: { exercise, weight in
                activeWorkoutStore.toggleWarmupComplete(weight, for: exercise.id)
                Haptics.setLogged()
                // Deliberately no rest timer here — warm-ups never trigger
                // rest, checked or unchecked.
            },
            onAddSet: { exercise in
                activeWorkoutStore.addExtraSet(for: exercise.id)
                Haptics.setLogged()
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

        let priorLogs = logStore.logs

        let previousLog = priorLogs
            .filter { $0.workoutName == log.workoutName }
            .max { $0.date < $1.date }

        let newPersonalRecords = WorkoutSessionEngine.newPersonalRecords(
            in: log,
            priorLogs: priorLogs
        )

        logStore.add(log)
        activeWorkoutStore.finish()

        completedWorkout = CompletedWorkout(
            log: log,
            previousLog: previousLog,
            newPersonalRecords: newPersonalRecords
        )
    }
}
