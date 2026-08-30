import Foundation

/// A calorie/macro target that took effect on a given date. Local-only —
/// HealthKit has no concept of a "goal," only logged samples, so this has
/// nowhere else to live.
struct MacroGoal: Codable, Identifiable, Equatable {
    let id: UUID
    let effectiveDate: Date
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int

    init(
        id: UUID = UUID(),
        effectiveDate: Date,
        calories: Int,
        proteinG: Int,
        carbsG: Int,
        fatG: Int
    ) {
        self.id = id
        self.effectiveDate = effectiveDate
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
    }
}
