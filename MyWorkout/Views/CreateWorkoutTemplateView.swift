import SwiftUI

struct CreateWorkoutTemplateView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @Environment(\.dismiss) private var dismiss

    @State private var templateName = ""
    @State private var selectedExerciseIDs: Set<UUID> = []
    @State private var selectedEquipment = "All"

    private let exercises = SeedData.exercises

    private var equipmentOptions: [String] {
        ["All"] + Array(Set(exercises.map { $0.equipment })).sorted()
    }

    private var filteredExercises: [Exercise] {
        if selectedEquipment == "All" {
            return exercises
        }

        return exercises.filter { $0.equipment == selectedEquipment }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Workout name", text: $templateName)
                .textFieldStyle(.roundedBorder)

            Picker("Equipment", selection: $selectedEquipment) {
                ForEach(equipmentOptions, id: \.self) { equipment in
                    Text(equipment).tag(equipment)
                }
            }
            .pickerStyle(.menu)

            List(filteredExercises) { exercise in
                Button {
                    toggle(exercise)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)

                            Text("\(exercise.muscleGroup) • \(exercise.equipment) • \(exercise.exerciseType.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if selectedExerciseIDs.contains(exercise.id) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }

            Button("Save Template") {
                saveTemplate()
            }
            .disabled(templateName.isEmpty || selectedExerciseIDs.isEmpty)
        }
        .padding()
        .navigationTitle("Create Template")
    }

    private func toggle(_ exercise: Exercise) {
        if selectedExerciseIDs.contains(exercise.id) {
            selectedExerciseIDs.remove(exercise.id)
        } else {
            selectedExerciseIDs.insert(exercise.id)
        }
    }

    private func saveTemplate() {
        let selectedExercises = exercises.filter {
            selectedExerciseIDs.contains($0.id)
        }

        let template = WorkoutTemplate(
            name: templateName,
            exercises: selectedExercises
        )

        templateStore.add(template)
        dismiss()
    }
}
