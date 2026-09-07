import Foundation

@MainActor
protocol MacroGoalReplacing {
    func replaceAll(
        with newGoals: [MacroGoal]
    )
}

extension MacroGoalStore: MacroGoalReplacing {}
