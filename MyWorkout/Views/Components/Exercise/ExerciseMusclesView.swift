import SwiftUI

struct ExerciseMusclesView: View {
    let exercise: Exercise

    var body: some View {
        if !exercise.primaryMuscles.isEmpty || !exercise.secondaryMuscles.isEmpty {
            Section("Muscles") {
                if !exercise.primaryMuscles.isEmpty {
                    muscleGroup(title: "Primary", muscles: exercise.primaryMuscles)
                }

                if !exercise.secondaryMuscles.isEmpty {
                    muscleGroup(title: "Secondary", muscles: exercise.secondaryMuscles)
                }
            }
        }
    }

    private func muscleGroup(title: String, muscles: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(muscles, id: \.self) { muscle in
                    InfoBadge(text: muscle)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ExerciseMusclesView(exercise: SeedData.exercises.first!)
    }
}
