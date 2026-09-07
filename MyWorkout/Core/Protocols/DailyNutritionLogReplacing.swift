import Foundation

@MainActor
protocol DailyNutritionLogReplacing {
    func replaceAll(
        with newLogs: [DailyNutritionLog]
    )
}

extension DailyNutritionLogStore: DailyNutritionLogReplacing {}
