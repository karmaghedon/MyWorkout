import SwiftUI

/// The "selected exercises" list shared by `CreateWorkoutTemplateView` and
/// `TemplateEditorView` — each row's sets/weight steppers, reordering,
/// deletion, and superset grouping. Extracted into one component because
/// these two screens already drifted out of sync once this session (the
/// "Add Exercises" bug traced to one carrying a modifier the other
/// didn't) — there's now a single place to get this right instead of two
/// to keep in sync.
///
/// Grouping mode swaps each row to a plain, non-interactive selectable
/// row (checkmark + name inside a single `Button`) rather than
/// overlaying a tap gesture on the normal row, which also hosts the
/// sets/weight `Stepper`s — a parent-level tap gesture competing with
/// those nested buttons is exactly the class of bug that broke "Add
/// Exercises" earlier this session.
struct TemplateExercisesSection: View {
    @Binding var exercises: [Exercise]

    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var equipmentStore: EquipmentInventoryStore

    @State private var isGroupingMode = false
    @State private var selectedForGrouping: Set<UUID> = []

    var body: some View {
        Section {
            if exercises.isEmpty {
                Text("No exercises added yet.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            ForEach($exercises) { $exercise in
                if isGroupingMode {
                    groupingSelectionRow(for: exercise)
                } else {
                    exerciseRow(for: $exercise)
                }
            }
            .onMove(perform: moveExercises)
            .onDelete(perform: deleteExercises)
        } header: {
            HStack {
                Text("Exercises")

                Spacer()

                if !exercises.isEmpty {
                    Button(isGroupingMode ? "Cancel" : "Group") {
                        toggleGroupingMode()
                    }
                    .font(AppTheme.Typography.caption)
                    .textCase(nil)
                }
            }
        } footer: {
            if isGroupingMode {
                Text("Select 2 or more exercises, then tap Create Superset below.")
            } else {
                Text("Tap Edit to reorder or remove exercises. Group exercises into a superset to perform them back-to-back with no rest between.")
            }
        }

        if isGroupingMode {
            Section {
                Button("Create Superset") {
                    createSuperset()
                }
                .disabled(selectedForGrouping.count < 2)
            }
        }
    }

    // MARK: - Rows

    private func exerciseRow(for exercise: Binding<Exercise>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ExerciseRowView(exercise: exercise.wrappedValue)

            if let groupID = exercise.wrappedValue.supersetGroupID {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "link")

                    Text("Superset · \(groupMemberCount(groupID)) exercises")

                    Spacer()

                    Button("Ungroup") {
                        ungroup(exercise.wrappedValue)
                    }
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.accent)
            }

            Stepper(
                "\(exercise.wrappedValue.targetSets) sets",
                value: exercise.targetSets,
                in: 1...10
            )
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.secondaryText)

            Stepper(
                "\(formatWeight(weightBinding(for: exercise).wrappedValue)) \(weightUnit)",
                value: weightBinding(for: exercise),
                in: 0...500,
                step: weightStep
            )
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.leading, exercise.wrappedValue.supersetGroupID != nil ? AppTheme.Spacing.sm : 0)
        .overlay(alignment: .leading) {
            if exercise.wrappedValue.supersetGroupID != nil {
                Rectangle()
                    .fill(AppTheme.accent)
                    .frame(width: 3)
            }
        }
    }

    private func groupingSelectionRow(for exercise: Exercise) -> some View {
        let isSelected = selectedForGrouping.contains(exercise.id)

        return Button {
            toggleSelection(exercise.id)
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.secondaryText)
                    .accessibilityHidden(true)

                ExerciseRowView(exercise: exercise)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
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

    // MARK: - Reorder / Delete

    private func moveExercises(
        from source: IndexSet,
        to destination: Int
    ) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteExercises(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    // MARK: - Grouping

    private func toggleGroupingMode() {
        isGroupingMode.toggle()
        selectedForGrouping = []
    }

    private func toggleSelection(_ id: UUID) {
        if selectedForGrouping.contains(id) {
            selectedForGrouping.remove(id)
        } else {
            selectedForGrouping.insert(id)
        }
    }

    /// Assigns a fresh shared group id to every selected exercise. If any
    /// selected exercise already belonged to a different group, it's
    /// simply pulled into this new one — its old groupmates are
    /// untouched (a group can end up with a single remaining member,
    /// which is harmless: `WorkoutSessionEngine.shouldStartRest` treats a
    /// lone member exactly like an ungrouped exercise).
    private func createSuperset() {
        guard selectedForGrouping.count >= 2 else {
            return
        }

        let newGroupID = UUID()

        for index in exercises.indices
        where selectedForGrouping.contains(exercises[index].id) {
            exercises[index].supersetGroupID = newGroupID
        }

        isGroupingMode = false
        selectedForGrouping = []
    }

    private func ungroup(_ exercise: Exercise) {
        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else {
            return
        }

        exercises[index].supersetGroupID = nil
    }

    private func groupMemberCount(_ groupID: UUID) -> Int {
        exercises.filter { $0.supersetGroupID == groupID }.count
    }
}
