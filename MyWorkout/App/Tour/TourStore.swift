import Foundation

/// Tracks whether the user has completed the app tour. Low-stakes
/// preference data — same treatment as `FavoriteExercisesStore`: a
/// single `UserDefaults`-backed flag, no envelope/migration, and
/// deliberately excluded from `MyWorkoutApp.flushAllPendingSaves()`
/// (losing this isn't a data-loss concern worth that treatment — worst
/// case the tour offers to run again).
@MainActor
final class TourStore: ObservableObject {
    @Published private(set) var hasCompletedTour: Bool

    private let key = "has_completed_tour"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.hasCompletedTour = userDefaults.bool(forKey: key)
    }

    func markCompleted() {
        hasCompletedTour = true
        userDefaults.set(true, forKey: key)
    }
}
