import Foundation

enum AppRoute: Hashable {
    // MARK: - Main Destinations

    case startWorkout
    case history
    case analytics
    case strengthTrends
    case templates
    case equipmentInventory
    case settings
    case export

    // MARK: - Detail Destinations

    case exerciseDetail(UUID)
    case workoutLogDetail(UUID)
    case editTemplate(UUID)
    case activeWorkout
}
