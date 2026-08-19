import SwiftUI

struct TemplateEditorView: View {
    @EnvironmentObject private var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore
    @Environment(\.dismiss) private var dismiss

    @State private var editableTemplate: WorkoutTemplate
    @State private var selectedEquipment: ExerciseEquipment?
    @State private var showingAddExercises = false

    init(template: WorkoutTemplate) {
        _editableTemplate = State(initialValue: template)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                templateNameSection
                addExercisesSection
                selectedExercisesSection
            }
            .scrollDismissesKeyboard(.interactively)

            duplicateButton
        }
        .navigationTitle("Edit Template")
        .toolbar {
            editorToolbar
        }
    }

    // MARK: - Sections

    private var templateNameSection: some View {
        Section {
            ValidatedNameField(
                title: "Template name",
                text: $editableTemplate.name
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

    private var selectedExercisesSection: some View {
        Section {
            ForEach(editableTemplate.exercises) { exercise in
                ExerciseRowView(exercise: exercise)
            }
            .onMove(perform: moveExercises)
            .onDelete(perform: deleteExercises)
        } header: {
            Text("Exercises")
        } footer: {
            Text("Tap Edit to reorder or remove exercises.")
        }
    }

    // MARK: - Bottom Action

    private var duplicateButton: some View {
        SecondaryButton(
            title: "Duplicate Template",
            systemImage: "doc.on.doc",
            isEnabled: canSave,
            action: duplicateTemplate
        )
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.groupedBackground)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            EditButton()

            Button("Save") {
                saveTemplate()
            }
            .fontWeight(.semibold)
            .disabled(!canSave)
        }
    }

    // MARK: - Derived State

    private var canSave: Bool {
        editableTemplate.name.isValidName
            && !editableTemplate.exercises.isEmpty
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
            !editableTemplate.exercises.contains {
                $0.id == exercise.id
            }
        }
    }

    // MARK: - Exercise Actions

    private func addExercise(_ exercise: Exercise) {
        editableTemplate.exercises.append(exercise)
        selectedEquipment = nil
        showingAddExercises = false
    }

    private func moveExercises(
        from source: IndexSet,
        to destination: Int
    ) {
        editableTemplate.exercises.move(
            fromOffsets: source,
            toOffset: destination
        )
    }

    private func deleteExercises(at offsets: IndexSet) {
        editableTemplate.exercises.remove(atOffsets: offsets)
    }

    // MARK: - Template Actions

    private func saveTemplate() {
        guard canSave else {
            return
        }

        normalizeTemplateName()
        templateStore.update(editableTemplate)
        dismiss()
    }

    private func duplicateTemplate() {
        guard canSave else {
            return
        }

        normalizeTemplateName()
        templateStore.duplicate(editableTemplate)
        dismiss()
    }

    private func normalizeTemplateName() {
        editableTemplate.name =
            editableTemplate.name.normalizedName
    }
}
