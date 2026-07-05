//import SwiftUI
//
//struct ExerciseDetailView: View {
//    let exercise: Exercise
//
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
//                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
//                    Text(exercise.muscleGroup)
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//
//                    Text(exercise.equipment)
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//
//                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
//                    Text("Instructions")
//                        .font(AppTheme.Typography.sectionTitle)
//
//                    Text(exercise.instructions)
//                        .font(.body)
//                }
//            }
//            .padding(AppTheme.Spacing.lg)
//        }
//        .navigationTitle(exercise.name)
//        #if os(iOS)
//        .navigationBarTitleDisplayMode(.inline)
//        #endif
//    }
//}


import SwiftUI

struct ExerciseDetailView: View {

    let exercise: Exercise
    
    @Environment(\.dismiss) private var dismiss
    var showsDoneButton: Bool = false

    var body: some View {
        NavigationStack {
            List {

                Section("Overview") {
                    DetailRow(title: "Muscle Group", value: exercise.muscleGroup)
                    DetailRow(title: "Equipment", value: exercise.equipment)
                    DetailRow(title: "Difficulty", value: exercise.difficulty)
                    DetailRow(title: "Type", value: exercise.exerciseType.rawValue.capitalized)
                }

                if !exercise.primaryMuscles.isEmpty {
                    Section("Primary Muscles") {
                        ForEach(exercise.primaryMuscles, id: \.self) {
                            Text($0)
                        }
                    }
                }

                if !exercise.secondaryMuscles.isEmpty {
                    Section("Secondary Muscles") {
                        ForEach(exercise.secondaryMuscles, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section("Instructions") {
                    Text(exercise.instructions)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !exercise.tips.isEmpty {
                    Section("Tips") {
                        ForEach(exercise.tips, id: \.self) {
                            Label($0, systemImage: "checkmark.circle.fill")
                        }
                    }
                }

                if !exercise.commonMistakes.isEmpty {
                    Section("Common Mistakes") {
                        ForEach(exercise.commonMistakes, id: \.self) {
                            Label($0, systemImage: "exclamationmark.triangle")
                        }
                    }
                }

                if !exercise.warnings.isEmpty {
                    Section("Safety") {
                        ForEach(exercise.warnings, id: \.self) {
                            Label($0, systemImage: "shield")
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
}

private struct DetailRow: View {

    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ExerciseDetailView(exercise: SeedData.exercises.first!)
}
