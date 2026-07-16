import SwiftUI

struct TemplateEditorView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
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
                Section {
                    ValidatedNameField(
                        title: "Template name",
                        text: $editableTemplate.name
                    )
                }

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
                        addExercisesPanel
                    }
                }

                Section {
                    ForEach(
                        Array(editableTemplate.exercises.enumerated()),
                        id: \.element.id
                    ) { index, exercise in
                        exerciseRow(
                            index: index,
                            exercise: exercise
                        )
                    }
                    .onMove(perform: moveExercises)
                    .onDelete(perform: deleteExercises)
                } header: {
                    Text("Exercises")
                } footer: {
                    Text("Tap Edit to reorder or remove exercises.")
                }
            }
            .scrollDismissesKeyboard(.interactively)

            Button {
                duplicateTemplate()
            } label: {
                Label(
                    "Duplicate Template",
                    systemImage: "doc.on.doc"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.groupedBackground)
        }
        .navigationTitle("Edit Template")
        .toolbar {
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
    }
    
    private var canSave: Bool {
        editableTemplate.name.isValidName
            && !editableTemplate.exercises.isEmpty
    }

    private func saveTemplate() {
        guard canSave else {
            return
        }

        editableTemplate.name =
            editableTemplate.name.normalizedName

        templateStore.update(editableTemplate)
        dismiss()
    }

    private func duplicateTemplate() {
        guard canSave else {
            return
        }

        editableTemplate.name =
            editableTemplate.name.normalizedName

        templateStore.duplicate(editableTemplate)
        dismiss()
    }
    
    private var addExercisesPanel: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Picker(
                "Equipment",
                selection: $selectedEquipment
            ) {
                Text("All")
                    .tag(ExerciseEquipment?.none)

                ForEach(equipmentOptions) { equipment in
                    Text(equipment.displayName)
                        .tag(Optional(equipment))
                }
            }
            .pickerStyle(.menu)

            if filteredAvailableExercises.isEmpty {
                Text("No exercises available to add")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredAvailableExercises) { exercise in
                    Button {
                        editableTemplate.exercises.append(exercise)
                        showingAddExercises = false
                    } label: {
                        HStack {
                            ExerciseRowView(exercise: exercise)

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                                .accessibilityHidden(true)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private func exerciseRow(index: Int, exercise: Exercise) -> some View {
        ExerciseRowView(exercise: exercise)
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        editableTemplate.exercises.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteExercises(at offsets: IndexSet) {
        editableTemplate.exercises.remove(atOffsets: offsets)
    }

    private var availableExercises: [Exercise] {
        let selectableExercises = ExerciseRegistry(
            sources: [
                BuiltInExerciseSource(),
                CustomExerciseSource(
                    exercises: customExerciseStore.activeExercises
                )
            ]
        ).exercises

        return selectableExercises.filter { exercise in
            !editableTemplate.exercises.contains {
                $0.id == exercise.id
            }
        }
    }

    private var equipmentOptions: [ExerciseEquipment] {
        Array(
            Set(availableExercises.map(\.equipment))
        )
        .sorted()
    }

    private var filteredAvailableExercises: [Exercise] {
        guard let selectedEquipment else {
            return availableExercises
        }

        return availableExercises.filter {
            $0.equipment == selectedEquipment
        }
    }
}
