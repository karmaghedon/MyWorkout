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

                Text("\(exercise.muscleGroup) • \(exercise.equipment) • \(exercise.exerciseType.rawValue.capitalized)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                InfoBadge(text: exercise.muscleGroup)
                InfoBadge(text: exercise.equipment, systemImage: iconName)
                InfoBadge(text: exercise.difficulty)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var iconName: String {
        if exercise.exerciseType == .bodyweight {
            return "figure.strengthtraining.traditional"
        }

        if exercise.equipment.lowercased().contains("barbell") {
            return "dumbbell.fill"
        }

        if exercise.equipment.lowercased().contains("dumbbell") {
            return "dumbbell"
        }

        return "figure.strengthtraining.functional"
    }
}

#Preview {
    ExerciseHeaderView(exercise: SeedData.exercises.first!)
        .padding()
}
