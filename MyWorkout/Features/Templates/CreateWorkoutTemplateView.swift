import SwiftUI

/// Mirrors `TemplateEditorView`'s structure deliberately — a `Form` with
/// an expandable, searchable `TemplateExercisePickerView` to add
/// exercises and a reorderable list of what's been picked so far, each
/// row carrying its own sets/weight steppers. The previous version used a
/// non-scrolling `VStack` with a plain `List` and a second, separate
/// configuration section below it; on a full exercise list that pushed
/// the sets/weight steppers off-screen since nothing above the Save
/// button could actually scroll.
struct CreateWorkoutTemplateView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore
    @Environment(\.dismiss) private var dismiss

    @State private var templateName = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var selectedEquipment: ExerciseEquipment?
    @State private var showingAddExercises = false

    var body: some View {
        Form {
            templateNameSection
            addExercisesSection
            TemplateExercisesSection(exercises: $selectedExercises)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Create Template")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                EditButton()

                Button("Save") {
                    saveTemplate()
                }
                .fontWeight(.semibold)
                .disabled(!canSave)
            }
        }
    }

    // MARK: - Sections

    private var templateNameSection: some View {
        Section {
            ValidatedNameField(
                title: "Template name",
                text: $templateName
            )
        }
    }

    private var addExercisesSection: some View {
        Section {
            Button {
                showingAddExercises.toggle()
            } label: {
                Label(
                    showingAddExercises
                        ? "Hide Exercises"
                        : "Add Exercises",
                    systemImage: showingAddExercises
                        ? "minus.circle"
                        : "plus.circle"
                )
            }

            if showingAddExercises {
                TemplateExercisePickerView(
                    selectedEquipment: $selectedEquipment,
                    exercises: availableExercises,
                    onSelect: addExercise
                )
            }
        }
    }

    // MARK: - Derived State

    private var canSave: Bool {
        templateName.isValidName
            && !selectedExercises.isEmpty
    }

    private var availableExercises: [Exercise] {
        let registry = ExerciseRegistry(
            sources: [
                BuiltInExerciseSource(),
                CustomExerciseSource(
                    exercises: customExerciseStore.activeExercises
                )
            ]
        )

        return registry.exercises.filter { exercise in
            !selectedExercises.contains {
                $0.id == exercise.id
            }
        }
    }

    // MARK: - Exercise Actions

    private func addExercise(_ exercise: Exercise) {
        selectedExercises.append(exercise)
        selectedEquipment = nil
        showingAddExercises = false
    }

    // MARK: - Template Actions

    private func saveTemplate() {
        guard canSave else {
            return
        }

        let template = WorkoutTemplate(
            name: templateName.normalizedName,
            exercises: selectedExercises
        )

        templateStore.add(template)
        dismiss()
    }
}
