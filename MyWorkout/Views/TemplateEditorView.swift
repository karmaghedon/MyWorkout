import SwiftUI

struct TemplateEditorView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @Environment(\.dismiss) private var dismiss

    @State private var editableTemplate: WorkoutTemplate
    @State private var selectedEquipment = "All"
    @State private var showingAddExercises = false

    init(template: WorkoutTemplate) {
        _editableTemplate = State(initialValue: template)
    }

    var body: some View {
        Form {
            Section {
                TextField("Template name", text: $editableTemplate.name)
                    .font(AppTheme.Typography.label)
            }

            Section {
                Button {
                    showingAddExercises.toggle()
                } label: {
                    Label(
                        showingAddExercises ? "Hide Exercises" : "Add Exercises",
                        systemImage: showingAddExercises ? "minus.circle" : "plus.circle"
                    )
                }

                if showingAddExercises {
                    addExercisesPanel
                }
            }

            Section {
                ForEach(Array(editableTemplate.exercises.enumerated()), id: \.element.id) { index, exercise in
                    exerciseRow(index: index, exercise: exercise)
                }
                .onMove(perform: moveExercises)
                .onDelete(perform: deleteExercises)
            } header: {
                Text("Exercises")
            } footer: {
                Text("Tap Edit to reorder or remove exercises.")
            }

            Section {
                Button {
                    templateStore.duplicate(editableTemplate)
                    dismiss()
                } label: {
                    Label("Duplicate Template", systemImage: "doc.on.doc")
                }
            }
        }
        .dismissKeyboardOnTap()
        .navigationTitle("Edit Template")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    templateStore.update(editableTemplate)
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(
                    editableTemplate.name.trimmingCharacters(in: .whitespaces).isEmpty ||
                    editableTemplate.exercises.isEmpty
                )
            }

            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
    }

    private var addExercisesPanel: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Picker("Equipment", selection: $selectedEquipment) {
                ForEach(equipmentOptions, id: \.self) { equipment in
                    Text(equipment).tag(equipment)
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
        SeedData.exercises.filter { exercise in
            !editableTemplate.exercises.contains(where: { $0.id == exercise.id })
        }
    }

    private var equipmentOptions: [String] {
        ["All"] + Array(Set(availableExercises.map { $0.equipment })).sorted()
    }

    private var filteredAvailableExercises: [Exercise] {
        if selectedEquipment == "All" {
            return availableExercises
        }

        return availableExercises.filter { $0.equipment == selectedEquipment }
    }
}
