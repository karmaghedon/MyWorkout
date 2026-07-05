import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise

    @Environment(\.dismiss) private var dismiss
    var showsDoneButton: Bool = false

    var body: some View {
        List {
            Section {
                ExerciseHeaderView(exercise: exercise)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            
            Section("Overview") {
                DetailRow(title: "Muscle Group", value: exercise.muscleGroup)
                DetailRow(title: "Equipment", value: exercise.equipment)
                DetailRow(title: "Difficulty", value: exercise.difficulty)
                DetailRow(title: "Type", value: exercise.exerciseType.rawValue.capitalized)
                DetailRow(title: "Progression", value: exercise.progressionStrategy.displayName)
            }

            if !exercise.primaryMuscles.isEmpty {
                Section("Primary Muscles") {
                    ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                        Text(muscle)
                    }
                }
            }

            if !exercise.secondaryMuscles.isEmpty {
                Section("Secondary Muscles") {
                    ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                        Text(muscle)
                    }
                }
            }

            Section("Instructions") {
                Text(exercise.instructions.isEmpty ? "No instructions available yet." : exercise.instructions)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !exercise.tips.isEmpty {
                Section("Tips") {
                    ForEach(exercise.tips, id: \.self) { tip in
                        Label(tip, systemImage: "checkmark.circle")
                    }
                }
            }

            if !exercise.commonMistakes.isEmpty {
                Section("Common Mistakes") {
                    ForEach(exercise.commonMistakes, id: \.self) { mistake in
                        Label(mistake, systemImage: "exclamationmark.triangle")
                    }
                }
            }

            if !exercise.warnings.isEmpty {
                Section("Safety") {
                    ForEach(exercise.warnings, id: \.self) { warning in
                        Label(warning, systemImage: "shield")
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
