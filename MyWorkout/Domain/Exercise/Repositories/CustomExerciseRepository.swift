import Foundation

protocol CustomExerciseRepository {
    func load() throws -> [StoredCustomExercise]

    func save(
        _ exercises: [StoredCustomExercise]
    ) throws
}
