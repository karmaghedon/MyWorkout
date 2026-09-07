import Foundation

protocol MacroGoalRepository {
    func load() throws -> [MacroGoal]

    func save(
        _ goals: [MacroGoal]
    ) throws
}
