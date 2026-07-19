import SwiftUI

struct ExerciseRowView: View {
    let exercise: Exercise

    var showsMuscleGroup: Bool = true
    var showsEquipment: Bool = true
    var showsExerciseType: Bool = true

    private var subtitleParts: [String] {
        var parts: [String] = []

        if showsMuscleGroup {
            parts.append(exercise.muscleGroup.displayName)
        }

        if showsEquipment {
            parts.append(exercise.equipment.displayName)
        }

        if showsExerciseType {
            parts.append(exercise.exerciseType.rawValue.capitalized)
        }

        return parts
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name)
                .font(.headline)
                .foregroundStyle(.primary)

            if !subtitleParts.isEmpty {
                Text(subtitleParts.joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    List {
        ExerciseRowView(exercise: SeedData.exercises.first!)
    }
}
