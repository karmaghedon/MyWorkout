import SwiftUI

struct ExerciseLibraryView: View {
    let exercises = SeedData.exercises

    @State private var expandedGroups: Set<String> = []
    
    private let initialDisplayCount = 10
    
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
                    let isExpanded = expandedGroups.contains(group.muscleGroup)
                    let displayedExercises = isExpanded ? group.exercises : Array(group.exercises.prefix(initialDisplayCount))
                    let hasMore = group.exercises.count > initialDisplayCount
                    
                    ForEach(displayedExercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseRowView(exercise: exercise)
                        }
                    }
                    
                    if hasMore && isExpanded {
                        Button {
                            expandedGroups.insert(group.muscleGroup)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Show \(group.exercises.count - initialDisplayCount) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical,4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Exercise Library")
    }
}
