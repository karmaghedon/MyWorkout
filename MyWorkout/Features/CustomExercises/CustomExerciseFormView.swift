import SwiftUI

struct CustomExerciseFormView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var customExerciseStore:
        CustomExerciseStore

    @State private var draft: CustomExerciseDraft

    private let mode: Mode

    enum Mode {
        case create
        case edit(Exercise)
    }

    init(
        mode: Mode
    ) {
        self.mode = mode

        switch mode {
        case .create:
            _draft = State(
                initialValue: CustomExerciseDraft()
            )

        case let .edit(exercise):
            _draft = State(
                initialValue: CustomExerciseDraft(
                    exercise: exercise
                )
            )
        }
    }

    var body: some View {
        Form {
            CustomExerciseIdentitySection(
                draft: $draft,
                muscleGroups: muscleGroups,
                equipmentOptions: equipmentOptions,
                nameValidationMessage:
                    nameValidationResult.message
            )

            CustomExerciseMusclesSection(
                draft: $draft
            )

            CustomExerciseEducationSections(
                draft: $draft
            )

            CustomExerciseProgressionSection(
                draft: $draft
            )

            Section {
                PrimaryButton(
                    title: actionTitle,
                    systemImage: actionSystemImage,
                    isEnabled: canSave,
                    action: save
                )
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(
                placement: .keyboard
            ) {
                Spacer()

                Button("Done") {
                    Keyboard.dismiss()
                }
            }
        }
    }

    // MARK: - Form Options

    private var muscleGroups: [MuscleGroup] {
        [
            .chest,
            .back,
            .shoulders,
            .quadriceps,
            .hamstrings,
            .glutes,
            .legs,
            .biceps,
            .triceps,
            .arms,
            .calves,
            .core,
            .fullBody
        ]
    }

    private var equipmentOptions: [ExerciseEquipment] {
        [
            .barbell,
            .dumbbell,
            .bodyweight,
            .kettlebellOrDumbbell,
            .cableOrBand
        ]
    }

    // MARK: - Presentation

    private var navigationTitle: String {
        switch mode {
        case .create:
            return "New Exercise"

        case .edit:
            return "Edit Exercise"
        }
    }

    private var actionTitle: LocalizedStringKey {
        switch mode {
        case .create:
            return "Create Exercise"

        case .edit:
            return "Save Changes"
        }
    }

    private var actionSystemImage: String {
        switch mode {
        case .create:
            return "plus"

        case .edit:
            return "checkmark"
        }
    }

    // MARK: - Validation

    private var exercisesReservedForNaming: [Exercise] {
        SeedData.exercises
            + customExerciseStore.allExercises
    }

    private var editedExerciseID: UUID? {
        switch mode {
        case .create:
            return nil

        case let .edit(exercise):
            return exercise.id
        }
    }

    private var nameValidationResult:
        ExerciseNameValidationResult {
        ExerciseNameValidator.validate(
            draft.name,
            existingExercises:
                exercisesReservedForNaming,
            excluding: editedExerciseID
        )
    }

    private var canSave: Bool {
        draft.canSave
            && nameValidationResult == .valid
    }

    // MARK: - Save

    private func save() {
        guard canSave else {
            return
        }

        let exercise = draft.makeExercise()
        let didSave: Bool

        switch mode {
        case .create:
            didSave = customExerciseStore.create(
                exercise
            )

        case .edit:
            didSave = customExerciseStore.update(
                exercise
            )
        }

        guard didSave else {
            return
        }

        dismiss()
    }
}
