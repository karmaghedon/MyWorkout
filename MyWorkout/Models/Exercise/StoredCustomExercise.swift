import Foundation

struct StoredCustomExercise:
    Identifiable,
    Codable {

    let exercise: Exercise
    var isArchived: Bool
    let createdAt: Date
    var updatedAt: Date

    var id: UUID {
        exercise.id
    }

    init(
        exercise: Exercise,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.exercise = exercise
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
