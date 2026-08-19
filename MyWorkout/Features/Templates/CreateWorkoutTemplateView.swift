import SwiftUI

struct CreateWorkoutTemplateView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore
    @Environment(\.dismiss) private var dismiss

    @State private var templateName = ""
    @State private var selectedExerciseIDs: Set<UUID> = []
    @State private var selectedEquipment: ExerciseEquipment?

    private var exercises: [Exercise] {
        ExerciseRegistry(
            sources: [
                BuiltInExerciseSource(),
                CustomExerciseSource(
                    exercises: customExerciseStore.activeExercises
                )
            ]
        ).exercises
    }

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

    private var selectedExercises: [Exercise] {
        exercises.filter {
            selectedExerciseIDs.contains($0.id)
        }
    }

    private var canSave: Bool {
        templateName.isValidName
            && !selectedExercises.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ValidatedNameField(
                title: "Template name",
                text: $templateName
            )
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
                let isSelected = selectedExerciseIDs.contains(
                    exercise.id
                )

                Button {
                    toggle(exercise)
                } label: {
                    HStack {
                        ExerciseRowView(
                            exercise: exercise
                        )

                        Spacer()

                        if isSelected {
                            Image(
                                systemName: "checkmark.circle.fill"
                            )
                            .accessibilityHidden(true)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(
                    isSelected ? [.isSelected] : []
                )
                .accessibilityValue(
                    isSelected ? "Selected" : ""
                )
            }

            PrimaryButton(
                title: "Save Template",
                systemImage: "checkmark",
                isEnabled: canSave,
                action: saveTemplate
            )
        }
        .padding()
        .dismissKeyboardOnTap()
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
