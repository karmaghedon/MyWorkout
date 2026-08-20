import SwiftUI

struct CreateWorkoutTemplateView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var equipmentStore: EquipmentInventoryStore
    @Environment(\.dismiss) private var dismiss

    @State private var templateName = ""
    @State private var selectedExerciseIDs: Set<UUID> = []
    @State private var selectedEquipment: ExerciseEquipment?
    @State private var searchText = ""
    @State private var targetSetsByExerciseID: [UUID: Int] = [:]
    @State private var targetWeightByExerciseID: [UUID: Double] = [:]

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
        var result = exercises

        if let selectedEquipment {
            result = result.filter {
                $0.equipment == selectedEquipment
            }
        }

        let trimmedSearch = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !trimmedSearch.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(trimmedSearch)
            }
        }

        return result
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
            .searchable(
                text: $searchText,
                prompt: "Search exercises"
            )

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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("SETS & STARTING WEIGHT")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.secondaryText)

            ForEach(selectedExercises) { exercise in
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(AppTheme.Typography.label)

                    Stepper(
                        "\(targetSetsByExerciseID[exercise.id] ?? 3) sets",
                        value: Binding(
                            get: { targetSetsByExerciseID[exercise.id] ?? 3 },
                            set: { targetSetsByExerciseID[exercise.id] = $0 }
                        ),
                        in: 1...10
                    )
                    .font(AppTheme.Typography.caption)

                    Stepper(
                        "\(formatWeight(weightBinding(for: exercise).wrappedValue)) \(weightUnit)",
                        value: weightBinding(for: exercise),
                        in: 0...500,
                        step: weightStep
                    )
                    .font(AppTheme.Typography.caption)
                }
                .padding(.bottom, AppTheme.Spacing.xs)
            }
        }
    }

    // MARK: - Weight Boundary

    private var weightUnit: String {
        settingsStore.settings.unitSystem.rawValue
    }

    private var weightStep: Double {
        WeightConversion.displayStep(
            fromStoredPounds: 5,
            unitSystem: settingsStore.settings.unitSystem
        )
    }

    private func displayWeight(_ storedPounds: Double) -> Double {
        WeightConversion.displayWeight(
            fromStoredPounds: storedPounds,
            unitSystem: settingsStore.settings.unitSystem
        )
    }

    private func defaultWeightPounds(for exercise: Exercise) -> Double {
        WorkoutSessionEngine.defaultStartingWeight(
            for: exercise,
            equipmentInventory: equipmentStore.inventory
        )
    }

    /// Displayed-unit binding backed by `targetWeightByExerciseID`
    /// (canonical pounds). Reads fall back to the exercise's normal
    /// equipment-derived default until the user actually moves the
    /// stepper, at which point `saveTemplate` picks up a real override.
    private func weightBinding(for exercise: Exercise) -> Binding<Double> {
        Binding(
            get: {
                displayWeight(
                    targetWeightByExerciseID[exercise.id]
                        ?? defaultWeightPounds(for: exercise)
                )
            },
            set: { displayedWeight in
                targetWeightByExerciseID[exercise.id] =
                    WeightConversion.storedPounds(
                        fromDisplayedWeight: displayedWeight,
                        unitSystem: settingsStore.settings.unitSystem
                    )
            }
        )
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
            configured.targetWeightPounds = targetWeightByExerciseID[exercise.id]
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
