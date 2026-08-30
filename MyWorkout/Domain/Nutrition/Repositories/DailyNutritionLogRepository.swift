import Foundation

protocol DailyNutritionLogRepository {
    func load() throws -> [DailyNutritionLog]

    func save(
        _ logs: [DailyNutritionLog]
    ) throws
}
