import Foundation

protocol WorkoutLogRepository {
    func load() throws -> [WorkoutLog]

    func save(
        _ logs: [WorkoutLog]
    ) throws
}
