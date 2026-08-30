import Foundation

protocol NutritionHealthKitServicing {
    /// Upserts one calendar day's dietary totals in HealthKit: replaces
    /// any samples this app previously wrote for that day with fresh
    /// ones, so editing a day's macros never leaves stale or
    /// double-counted samples behind.
    func logDailyTotals(
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        calories: Double,
        date: Date
    ) async throws
}
