import SwiftUI

struct ExerciseHeaderView: View {
    let exercise: Exercise

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 42))
                .foregroundStyle(.blue)

            VStack(spacing: 4) {
                Text(exercise.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(
                    "\(exercise.muscleGroup.displayName) • \(exercise.equipment.displayName) • \(exercise.exerciseType.rawValue.capitalized)"
                )
                    .font(.subheadline)
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
