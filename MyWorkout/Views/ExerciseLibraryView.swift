import SwiftUI

struct ExerciseLibraryView: View {
    let exercises = SeedData.exercises

    private var groupedExercises: [(muscleGroup: String, exercises: [Exercise])] {
        let grouped = Dictionary(grouping: exercises) { $0.muscleGroup }

        return grouped
            .map { (muscleGroup: $0.key, exercises: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.muscleGroup < $1.muscleGroup }
    }

    var body: some View {
        List {
            ForEach(groupedExercises, id: \.muscleGroup) { group in
                Section(group.muscleGroup) {
                    ForEach(group.exercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseRowView(exercise: exercise)
                        }
                    }
                }
            }
        }
        .navigationTitle("Exercise Library")
    }
}
