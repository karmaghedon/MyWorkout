import Foundation
@testable import MyWorkout

enum WorkoutTemplateTestFactory {

    static func make(
        id: UUID = UUID(),
        name: String = "Test Template",
        exercises: [Exercise]? = nil
    ) -> WorkoutTemplate {
        WorkoutTemplate(
            id: id,
            name: name,
            exercises:
                exercises
                ?? SeedData.defaultTemplates.first?.exercises
                ?? []
        )
    }
}
