import SwiftUI

struct CustomExercisesView: View {
    @EnvironmentObject private var customExerciseStore:
        CustomExerciseStore

    @EnvironmentObject private var templateStore:
        WorkoutTemplateStore

    @EnvironmentObject private var logStore:
        WorkoutLogStore

    @EnvironmentObject private var activeWorkoutStore:
        ActiveWorkoutStore

    @State private var exercisePendingArchive: Exercise?
    @State private var exercisePendingDeletion: Exercise?
    @State private var deletionBlockedMessage: String?

    let onCreateExercise: () -> Void
    let onEditExercise: (Exercise) -> Void

    var body: some View {
        List {
            activeExercisesSection
            archivedExercisesSection
        }
        .overlay {
            if customExerciseStore.storedExercises.isEmpty {
                AppEmptyStateView(
                    title: "No Custom Exercises",
                    message: "Create an exercise tailored to your training and equipment.",
                    systemImage: "figure.strengthtraining.traditional"
                )
            }
        }
        .navigationTitle("Custom Exercises")
        .toolbar {
            ToolbarItem(
                placement: .primaryAction
            ) {
                Button(
                    action: onCreateExercise
                ) {
                    Label(
                        "Create Exercise",
                        systemImage: "plus"
                    )
                }
                .accessibilityHint(
                    "Opens the custom exercise creation form."
                )
            }
        }
        .confirmationDialog(
            archiveDialogTitle,
            isPresented: archiveDialogBinding,
            titleVisibility: .visible
        ) {
            if let exercise = exercisePendingArchive {
                Button(
                    "Archive Exercise",
                    role: .destructive
                ) {
                    archive(exercise)
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
                exercisePendingArchive = nil
            }
        } message: {
            Text(archiveDialogMessage)
        }
        .confirmationDialog(
            deletionDialogTitle,
            isPresented: deletionDialogBinding,
            titleVisibility: .visible
        ) {
            if let exercise = exercisePendingDeletion {
                Button(
                    "Delete Permanently",
                    role: .destructive
                ) {
                    permanentlyDelete(exercise)
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
                exercisePendingDeletion = nil
            }
        } message: {
            Text(
                "This action cannot be undone."
            )
        }
        .alert(
            "Exercise Cannot Be Deleted",
            isPresented: deletionBlockedAlertBinding
        ) {
            Button(
                "OK",
                role: .cancel
            ) {
                deletionBlockedMessage = nil
            }
        } message: {
            Text(
                deletionBlockedMessage ?? ""
            )
        }
    }

    // MARK: - Active Exercises

    @ViewBuilder
    private var activeExercisesSection: some View {
        if !customExerciseStore.activeExercises.isEmpty {
            Section {
                ForEach(
                    customExerciseStore.activeExercises
                ) { exercise in
                    activeExerciseRow(exercise)
                }
            } header: {
                Text("Active")
            }
        }
    }

    private func activeExerciseRow(
        _ exercise: Exercise
    ) -> some View {
        CustomExerciseRow(
            exercise: exercise,
            style: .active,
            onSelect: {
                onEditExercise(exercise)
            },
            onArchive: {
                exercisePendingArchive = exercise
            },
            onRestore: {},
            onDelete: {}
        )
    }

    // MARK: - Archived Exercises

    @ViewBuilder
    private var archivedExercisesSection: some View {
        if !customExerciseStore.archivedExercises.isEmpty {
            Section {
                ForEach(
                    customExerciseStore.archivedExercises
                ) { exercise in
                    archivedExerciseRow(exercise)
                }
            } header: {
                Text("Archived")
            } footer: {
                Text(
                    "Archived exercises remain available to existing templates and workout history."
                )
            }
        }
    }

    private func archivedExerciseRow(
        _ exercise: Exercise
    ) -> some View {
        CustomExerciseRow(
            exercise: exercise,
            style: .archived,
            onSelect: {},
            onArchive: {},
            onRestore: {
                customExerciseStore.restore(
                    exerciseID: exercise.id
                )
            },
            onDelete: {
                requestPermanentDeletion(exercise)
            }
        )
    }

    // MARK: - Archive Confirmation

    private var archiveDialogBinding: Binding<Bool> {
        Binding(
            get: {
                exercisePendingArchive != nil
            },
            set: { isPresented in
                if !isPresented {
                    exercisePendingArchive = nil
                }
            }
        )
    }

    private var archiveDialogTitle: String {
        guard let exercise = exercisePendingArchive else {
            return "Archive Exercise?"
        }

        return "Archive \(exercise.name)?"
    }

    private var archiveDialogMessage: String {
        guard let exercise = exercisePendingArchive else {
            return ""
        }

        let status = referenceStatus(
            for: exercise
        )

        guard status.isReferenced else {
            return "The exercise will be removed from new exercise selections. You can restore it later."
        }

        let references = referenceDescriptions(
            for: status
        )

        return """
        This exercise is currently used by \(references.joined(separator: ", ")). Archiving keeps those existing references intact, but removes the exercise from new selections.
        """
    }

    private func archive(
        _ exercise: Exercise
    ) {
        customExerciseStore.archive(
            exerciseID: exercise.id
        )

        exercisePendingArchive = nil
    }

    // MARK: - Permanent Deletion

    private var deletionDialogBinding: Binding<Bool> {
        Binding(
            get: {
                exercisePendingDeletion != nil
            },
            set: { isPresented in
                if !isPresented {
                    exercisePendingDeletion = nil
                }
            }
        )
    }

    private var deletionDialogTitle: String {
        guard let exercise = exercisePendingDeletion else {
            return "Delete Exercise Permanently?"
        }

        return "Delete \(exercise.name) Permanently?"
    }

    private var deletionBlockedAlertBinding: Binding<Bool> {
        Binding(
            get: {
                deletionBlockedMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    deletionBlockedMessage = nil
                }
            }
        )
    }

    private func requestPermanentDeletion(
        _ exercise: Exercise
    ) {
        let status = referenceStatus(
            for: exercise
        )

        guard !status.isReferenced else {
            let references = referenceDescriptions(
                for: status
            )

            deletionBlockedMessage = """
            This exercise cannot be permanently deleted because it is still used by \(references.joined(separator: ", ")). Keep it archived instead.
            """

            return
        }

        exercisePendingDeletion = exercise
    }

    private func permanentlyDelete(
        _ exercise: Exercise
    ) {
        let wasDeleted =
            customExerciseStore.permanentlyDelete(
                exerciseID: exercise.id
            )

        if wasDeleted {
            exercisePendingDeletion = nil
        }
    }

    // MARK: - Reference Checking

    private func referenceStatus(
        for exercise: Exercise
    ) -> ExerciseReferenceStatus {
        ExerciseReferenceChecker.status(
            for: exercise.id,
            templates: templateStore.templates,
            logs: logStore.logs,
            activeWorkout: activeWorkoutStore.activeWorkout
        )
    }

    private func referenceDescriptions(
        for status: ExerciseReferenceStatus
    ) -> [String] {
        var descriptions: [String] = []

        if status.isUsedByTemplates {
            descriptions.append(
                "workout templates"
            )
        }

        if status.isUsedByHistory {
            descriptions.append(
                "workout history"
            )
        }

        if status.isUsedByActiveWorkout {
            descriptions.append(
                "the active workout"
            )
        }

        return descriptions
    }
}
