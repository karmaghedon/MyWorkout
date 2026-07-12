import SwiftUI

struct CreateWorkoutTemplateView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @Environment(\.dismiss) private var dismiss

    @State private var templateName = ""
    @State private var selectedExerciseIDs: Set<UUID> = []
    @State private var selectedEquipment: ExerciseEquipment?

    private let exercises = SeedData.exercises

    private var equipmentOptions: [ExerciseEquipment] {
        Array(
            Set(exercises.map(\.equipment))
        )
        .sorted()
    }

    private var filteredExercises: [Exercise] {
        guard let selectedEquipment else {
            return exercises
        }

        return exercises.filter {
            $0.equipment == selectedEquipment
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Workout name", text: $templateName)
                .textFieldStyle(.roundedBorder)

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

            List(filteredExercises) { exercise in
                let isSelected = selectedExerciseIDs.contains(exercise.id)

                Button {
                    toggle(exercise)
                } label: {
                    HStack {
                        ExerciseRowView(exercise: exercise)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                .accessibilityValue(isSelected ? "Selected" : "")
            }

            Button("Save Template") {
                saveTemplate()
            }
            .disabled(!canSave)
        }
        .padding()
        .dismissKeyboardOnTap()
        .navigationTitle("Create Template")
    }
    
    private var canSave: Bool {
        InputValidation.isValidName(templateName) && !selectedExerciseIDs.isEmpty
    }

    private func toggle(_ exercise: Exercise) {
        if selectedExerciseIDs.contains(exercise.id) {
            selectedExerciseIDs.remove(exercise.id)
        } else {
            selectedExerciseIDs.insert(exercise.id)
        }
    }

    private func saveTemplate() {
        guard let validName = InputValidation.validateName(templateName) else {
            return
        }
        let selectedExercises = exercises.filter {
            selectedExerciseIDs.contains($0.id)
        }

        let template = WorkoutTemplate(
            name: validName,
            exercises: selectedExercises
        )

        templateStore.add(template)
        dismiss()
    }
}
