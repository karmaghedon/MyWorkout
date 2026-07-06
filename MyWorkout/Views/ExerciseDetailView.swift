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
            
            ExerciseOverviewView(exercise: exercise)

            ExerciseMusclesView(exercise: exercise)
            ExerciseInstructionsView(exercise: exercise)
            ExerciseTipsView(exercise: exercise)
            ExerciseWarningsView(exercise: exercise)
            
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
