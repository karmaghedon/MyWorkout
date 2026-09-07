import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore
    var showsDoneButton: Bool = false

    private var relatedExercises: [Exercise] {
        let allExercises = ExerciseRegistry(
            sources: [
                BuiltInExerciseSource(),
                CustomExerciseSource(
                    exercises: customExerciseStore.activeExercises
                )
            ]
        ).exercises

        return Array(
            allExercises
                .filter {
                    $0.muscleGroup == exercise.muscleGroup
                        && $0.id != exercise.id
                }
                .sorted { $0.name < $1.name }
                .prefix(4)
        )
    }

    var body: some View {
        List {
            Section {
                ExerciseHeaderView(exercise: exercise)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            ExerciseOverviewView(exercise: exercise)

            ExerciseMusclesView(exercise: exercise)
            ExerciseInstructionsView(exercise: exercise)
            ExerciseTipsView(exercise: exercise)
            ExerciseWarningsView(exercise: exercise)

            if !relatedExercises.isEmpty {
                Section("Related Exercises") {
                    ForEach(relatedExercises) { related in
                        NavigationLink {
                            ExerciseDetailView(exercise: related)
                        } label: {
                            ExerciseRowView(exercise: related)
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: SeedData.exercises.first!)
    }
}
