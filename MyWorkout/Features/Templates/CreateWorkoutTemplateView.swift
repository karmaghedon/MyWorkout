import SwiftUI

/// Mirrors `TemplateEditorView`'s structure deliberately — a `Form` with
/// an expandable, searchable `TemplateExercisePickerView` to add
/// exercises and a reorderable list of what's been picked so far, each
/// row carrying its own sets/weight steppers. The previous version used a
/// non-scrolling `VStack` with a plain `List` and a second, separate
/// configuration section below it; on a full exercise list that pushed
/// the sets/weight steppers off-screen since nothing above the Save
/// button could actually scroll.
struct CreateWorkoutTemplateView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var equipmentStore: EquipmentInventoryStore
    @Environment(\.dismiss) private var dismiss

    @State private var templateName = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var selectedEquipment: ExerciseEquipment?
    @State private var showingAddExercises = false

    var body: some View {
        Form {
            templateNameSection
            addExercisesSection
            selectedExercisesSection
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Create Template")
        .toolbar {
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

    // MARK: - Sections

    private var templateNameSection: some View {
        Section {
            ValidatedNameField(
                title: "Template name",
                text: $templateName
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
            if selectedExercises.isEmpty {
                Text("No exercises added yet.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            ForEach($selectedExercises) { $exercise in
                VStack(alignment: .leading, spacing: 4) {
                    ExerciseRowView(exercise: exercise)

                    Stepper(
                        "\(exercise.targetSets) sets",
                        value: $exercise.targetSets,
                        in: 1...10
                    )
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.secondaryText)

                    Stepper(
                        "\(formatWeight(weightBinding(for: $exercise).wrappedValue)) \(weightUnit)",
                        value: weightBinding(for: $exercise),
                        in: 0...500,
                        step: weightStep
                    )
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .onMove(perform: moveExercises)
            .onDelete(perform: deleteExercises)
        } header: {
            Text("Exercises")
        } footer: {
            Text("Tap Edit to reorder or remove exercises.")
        }
    }

    // MARK: - Derived State

    private var canSave: Bool {
        templateName.isValidName
            && !selectedExercises.isEmpty
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
            !selectedExercises.contains {
                $0.id == exercise.id
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

    private func weightBinding(for exercise: Binding<Exercise>) -> Binding<Double> {
        Binding(
            get: {
                displayWeight(
                    exercise.wrappedValue.targetWeightPounds
                        ?? defaultWeightPounds(for: exercise.wrappedValue)
                )
            },
            set: { displayedWeight in
                exercise.wrappedValue.targetWeightPounds =
                    WeightConversion.storedPounds(
                        fromDisplayedWeight: displayedWeight,
                        unitSystem: settingsStore.settings.unitSystem
                    )
            }
        )
    }

    // MARK: - Exercise Actions

    private func addExercise(_ exercise: Exercise) {
        selectedExercises.append(exercise)
        selectedEquipment = nil
        showingAddExercises = false
    }

    private func moveExercises(
        from source: IndexSet,
        to destination: Int
    ) {
        selectedExercises.move(
            fromOffsets: source,
            toOffset: destination
        )
    }

    private func deleteExercises(at offsets: IndexSet) {
        selectedExercises.remove(atOffsets: offsets)
    }

    // MARK: - Template Actions

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
