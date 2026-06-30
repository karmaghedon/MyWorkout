import SwiftUI

struct TemplateEditorView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @Environment(\.dismiss) private var dismiss

    @State private var editableTemplate: WorkoutTemplate

    init(template: WorkoutTemplate) {
        _editableTemplate = State(initialValue: template)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Template name", text: $editableTemplate.name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            List {
                ForEach(Array(editableTemplate.exercises.enumerated()), id: \.element.id) { index, exercise in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)

                            Text("\(exercise.muscleGroup) • \(exercise.equipment)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("↑") {
                            moveUp(index)
                        }
                        .disabled(index == 0)

                        Button("↓") {
                            moveDown(index)
                        }
                        .disabled(index == editableTemplate.exercises.count - 1)

                        Button("Delete") {
                            deleteExercise(index)
                        }
                    }
                }
            }

            HStack {
                Button("Save Changes") {
                    templateStore.update(editableTemplate)
                    dismiss()
                }

                Button("Duplicate") {
                    templateStore.duplicate(editableTemplate)
                    dismiss()
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
        }
        .navigationTitle("Edit Template")
    }

    private func moveUp(_ index: Int) {
        guard index > 0 else { return }
        editableTemplate.exercises.swapAt(index, index - 1)
    }

    private func moveDown(_ index: Int) {
        guard index < editableTemplate.exercises.count - 1 else { return }
        editableTemplate.exercises.swapAt(index, index + 1)
    }

    private func deleteExercise(_ index: Int) {
        editableTemplate.exercises.remove(at: index)
    }
}
