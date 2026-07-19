import Foundation

@MainActor
protocol WorkoutLogReplacing {
    func replaceAll(
        with newLogs: [WorkoutLog]
    )
}

extension WorkoutLogStore:
    WorkoutLogReplacing {}
