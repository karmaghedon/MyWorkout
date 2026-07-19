import SwiftUI

struct TemplateExercisePickerView: View {
    @Binding var selectedEquipment: ExerciseEquipment?

    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: AppTheme.Spacing.sm
        ) {
            equipmentPicker

            if filteredExercises.isEmpty {
                emptyState
            } else {
                exerciseList
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var equipmentPicker: some View {
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
    }

    private var emptyState: some View {
        Text("No exercises available to add")
            .font(AppTheme.Typography.caption)
            .foregroundStyle(.secondary)
    }

    private var exerciseList: some View {
        ForEach(filteredExercises) { exercise in
            Button {
                onSelect(exercise)
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
            .accessibilityLabel("Add \(exercise.name)")
        }
    }

    private var equipmentOptions: [ExerciseEquipment] {
        Array(Set(exercises.map(\.equipment)))
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
}
