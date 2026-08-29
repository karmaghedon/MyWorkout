import SwiftUI

struct ExerciseHeaderView: View {
    let exercise: Exercise

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 42))
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(exercise.name)
                    .font(AppTheme.Typography.screenTitle)
                    .multilineTextAlignment(.center)

                Text(
                    "\(exercise.muscleGroup.displayName) • \(exercise.equipment.displayName) • \(exercise.exerciseType.rawValue.capitalized)"
                )
                    .font(AppTheme.Typography.label)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                InfoBadge(text: exercise.muscleGroup.displayName)
                InfoBadge(
                    text: exercise.equipment.displayName,
                    systemImage: exercise.equipment.systemImage
                )
                InfoBadge(text: exercise.difficulty)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var iconName: String {
        exercise.equipment.systemImage
    }
}

#Preview {
    ExerciseHeaderView(exercise: SeedData.exercises.first!)
        .padding()
}
