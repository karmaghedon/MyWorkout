import SwiftUI

struct CustomExercisesView: View {
    @EnvironmentObject private var customExerciseStore:
        CustomExerciseStore

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
        Button {
            onEditExercise(exercise)
        } label: {
            HStack(
                spacing: AppTheme.Spacing.sm
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(exerciseSummary(exercise))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(exercise.name), \(exerciseSummary(exercise))"
        )
        .accessibilityHint(
            "Opens this custom exercise for editing."
        )
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {
            Button(
                role: .destructive
            ) {
                customExerciseStore.archive(
                    exerciseID: exercise.id
                )
            } label: {
                Label(
                    "Archive",
                    systemImage: "archivebox"
                )
            }
        }
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
                    "Archived exercises remain available to "
                    + "existing templates and workout history."
                )
            }
        }
    }

    private func archivedExerciseRow(
        _ exercise: Exercise
    ) -> some View {
        HStack(
            spacing: AppTheme.Spacing.sm
        ) {
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(exercise.name)
                    .font(.headline)

                Text(exerciseSummary(exercise))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                customExerciseStore.restore(
                    exerciseID: exercise.id
                )
            } label: {
                Label(
                    "Restore",
                    systemImage: "arrow.uturn.backward"
                )
                .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                "Restore \(exercise.name)"
            )
            .accessibilityHint(
                "Makes this exercise active again."
            )
        }
    }

    // MARK: - Presentation

    private func exerciseSummary(
        _ exercise: Exercise
    ) -> String {
        "\(exercise.muscleGroup.displayName) · "
            + exercise.equipment.displayName
    }
}
