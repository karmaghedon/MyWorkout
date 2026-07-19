import Foundation

protocol WorkoutTemplateRepository {
    func load() throws -> [WorkoutTemplate]

    func save(
        _ templates: [WorkoutTemplate]
    ) throws
}
