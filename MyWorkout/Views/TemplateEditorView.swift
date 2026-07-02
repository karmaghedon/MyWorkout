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
                #if os(iOS)
                .onMove(perform: moveExercises)
                .onDelete(perform: deleteExercises)
                #endif
            } header: {
                Text("Exercises")
            } footer: {
                #if os(iOS)
                Text("Tap Edit to reorder or remove exercises.")
                #else
                Text("Use the arrows to reorder, or the trash icon to remove an exercise.")
                #endif
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
                .disabled(editableTemplate.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            #if os(iOS)
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
            #endif
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.headline)

                                Text("\(exercise.muscleGroup) • \(exercise.equipment)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private func exerciseRow(index: Int, exercise: Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.headline)

                Text("\(exercise.muscleGroup) • \(exercise.equipment)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            #if os(macOS)
            Spacer()

            VStack(spacing: 4) {
                Button {
                    moveExercise(at: index, offset: -1)
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)
                .disabled(index == 0)

                Button {
                    moveExercise(at: index, offset: 1)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
                .disabled(index == editableTemplate.exercises.count - 1)
            }

            Button(role: .destructive) {
                deleteExercise(at: index)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            #endif
        }
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        editableTemplate.exercises.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteExercises(at offsets: IndexSet) {
        editableTemplate.exercises.remove(atOffsets: offsets)
    }

    #if os(macOS)
    private func moveExercise(at index: Int, offset: Int) {
        let destination = index + offset
        guard editableTemplate.exercises.indices.contains(destination) else { return }
        editableTemplate.exercises.swapAt(index, destination)
    }

    private func deleteExercise(at index: Int) {
        editableTemplate.exercises.remove(at: index)
    }
    #endif

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
