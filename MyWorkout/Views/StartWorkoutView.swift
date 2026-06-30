import SwiftUI

struct StartWorkoutView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore

    var body: some View {
        List {
            ForEach(templateStore.templates) { template in
                NavigationLink(template.name) {
                    WorkoutSessionView(
                        workout: Workout(
                            name: template.name,
                            exercises: template.exercises
                        )
                    )
                }
            }
            .onDelete(perform: templateStore.delete)
        }
        .navigationTitle("Start Workout")
    }
}
