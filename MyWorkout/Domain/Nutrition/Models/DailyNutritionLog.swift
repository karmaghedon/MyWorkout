import Foundation

/// A day's total macros — one record per calendar day, edited in place
/// rather than accumulated from individual food items. This app tracks
/// calories and macros, not a food diary: there is no food name or meal
/// type here, only the day's protein/carbs/fat.
///
/// Calories are always derived from macros via the standard 4/4/9
/// kcal-per-gram rule (protein ×4, carbs ×4, fat ×9) rather than entered
/// separately, so it's a computed property rather than a stored field —
/// there is no way for it to drift out of sync with the macros it's
/// derived from.
struct DailyNutritionLog: Codable, Identifiable, Equatable {
    let id: UUID
    /// Normalized to the start of its calendar day — `DailyNutritionLogStore`
    /// keeps at most one record per day and relies on this for that lookup.
    let date: Date
    let proteinG: Int
    let carbsG: Int
    let fatG: Int

    init(
        id: UUID = UUID(),
        date: Date,
        proteinG: Int,
        carbsG: Int,
        fatG: Int
    ) {
        self.id = id
        self.date = date
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
    }

    var calories: Int {
        proteinG * 4 + carbsG * 4 + fatG * 9
    }
}
