import SwiftUI

struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.accentMuted)

                Image(systemName: exercise.equipment.systemImage)
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(.primary)

                HStack(spacing: AppTheme.Spacing.xs) {
                    Chip(text: exercise.muscleGroup.displayName)
                    Chip(text: exercise.equipment.displayName)
                    Chip(text: exercise.difficulty)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        ExerciseRowView(exercise: SeedData.exercises.first!)
    }
}
