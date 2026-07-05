import SwiftUI

struct WorkoutSessionDialogs: ViewModifier {
    @Binding var showFinishSummary: Bool
    @Binding var showLeaveConfirmation: Bool
    @Binding var showCancelConfirmation: Bool

    let summaryText: String
    let onFinish: () -> Void
    let onKeepWorkoutRunning: () -> Void
    let onCancelWorkout: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Finish Workout?",
                isPresented: $showFinishSummary,
                titleVisibility: .visible
            ) {
                Button("Save Workout") {
                    onFinish()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text(summaryText)
            }
            .confirmationDialog(
                "Leave workout?",
                isPresented: $showLeaveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Keep Workout Running") {
                    onKeepWorkoutRunning()
                }

                Button("Cancel Workout", role: .destructive) {
                    onCancelWorkout()
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
                    onCancelWorkout()
                }

                Button("Keep Workout", role: .cancel) {}
            } message: {
                Text("This will discard the current workout and all logged sets.")
            }
    }
}

extension View {
    func workoutSessionDialogs(
        showFinishSummary: Binding<Bool>,
        showLeaveConfirmation: Binding<Bool>,
        showCancelConfirmation: Binding<Bool>,
        summaryText: String,
        onFinish: @escaping () -> Void,
        onKeepWorkoutRunning: @escaping () -> Void,
        onCancelWorkout: @escaping () -> Void
    ) -> some View {
        modifier(
            WorkoutSessionDialogs(
                showFinishSummary: showFinishSummary,
                showLeaveConfirmation: showLeaveConfirmation,
                showCancelConfirmation: showCancelConfirmation,
                summaryText: summaryText,
                onFinish: onFinish,
                onKeepWorkoutRunning: onKeepWorkoutRunning,
                onCancelWorkout: onCancelWorkout
            )
        )
    }
}
