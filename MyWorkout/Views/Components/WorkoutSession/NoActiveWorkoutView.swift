import SwiftUI

struct NoActiveWorkoutView: View {
    var body: some View {
        ContentUnavailableView(
            "No Active Workout",
            systemImage: "figure.strengthtraining.traditional",
            description: Text("Start a workout from a template.")
        )
    }
}
