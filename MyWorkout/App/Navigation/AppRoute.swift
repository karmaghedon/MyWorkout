import Foundation

enum AppRoute: Hashable {
    // MARK: - Main Destinations

    case startWorkout
    case history
    case analytics
    case strengthTrends
    case templates
    case equipmentInventory
    case customExercises
    case settings
    case export
    case logWeight
    case macroGoals
    case logNutrition
    case weeklyReport

    // MARK: - Detail Destinations

    case exerciseDetail(UUID)
    case workoutLogDetail(UUID)
    case editTemplate(UUID)
    case activeWorkout
    case createCustomExercise
    case editCustomExercise(UUID)
}
