import SwiftUI

struct ExerciseTipsView: View {
    let exercise: Exercise

    var body: some View {
        if !exercise.tips.isEmpty {
            Section("Tips") {
                ForEach(exercise.tips, id: \.self) { tip in
                    Label(tip, systemImage: "checkmark.circle")
                }
            }
        }
    }
}

#Preview {
    List {
        ExerciseTipsView(exercise: SeedData.exercises.first!)
    }
}
