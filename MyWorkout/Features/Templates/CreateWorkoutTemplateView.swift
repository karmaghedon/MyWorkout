import SwiftUI

struct CreateWorkoutTemplateView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore
    @Environment(\.dismiss) private var dismiss

    @State private var templateName = ""
    @State private var selectedExerciseIDs: Set<UUID> = []
    @State private var selectedEquipment: ExerciseEquipment?
    @State private var targetSetsByExerciseID: [UUID: Int] = [:]

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

            if !selectedExercises.isEmpty {
                configureSetsSection
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

    private var configureSetsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("SETS PER EXERCISE")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.secondaryText)

            ForEach(selectedExercises) { exercise in
                Stepper(
                    "\(exercise.name): \(targetSetsByExerciseID[exercise.id] ?? 3) sets",
                    value: Binding(
                        get: { targetSetsByExerciseID[exercise.id] ?? 3 },
                        set: { targetSetsByExerciseID[exercise.id] = $0 }
                    ),
                    in: 1...10
                )
                .font(AppTheme.Typography.caption)
            }
        }
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

        let exercisesWithSetCounts = selectedExercises.map { exercise -> Exercise in
            var configured = exercise
            configured.targetSets = targetSetsByExerciseID[exercise.id] ?? 3
            return configured
        }

        let template = WorkoutTemplate(
            name: templateName.normalizedName,
            exercises: exercisesWithSetCounts
        )

        templateStore.add(template)
        dismiss()
    }
}
