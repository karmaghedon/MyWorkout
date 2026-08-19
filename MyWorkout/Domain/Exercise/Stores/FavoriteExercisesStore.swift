import Foundation

/// Tracks which exercises (built-in or custom) the user has favorited.
/// Low-stakes preference data — unlike workout logs/templates/settings,
/// losing this isn't a data-loss concern worth the full corruption-
/// protection treatment those stores use, so this stays intentionally
/// simple: a single `Set<UUID>` in UserDefaults, no envelope/migration.
@MainActor
final class FavoriteExercisesStore: ObservableObject {
    @Published private(set) var favoriteExerciseIDs: Set<UUID> = []

    private let key = "favorite_exercise_ids"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func isFavorite(_ exerciseID: UUID) -> Bool {
        favoriteExerciseIDs.contains(exerciseID)
    }

    func toggleFavorite(_ exerciseID: UUID) {
        if favoriteExerciseIDs.contains(exerciseID) {
            favoriteExerciseIDs.remove(exerciseID)
        } else {
            favoriteExerciseIDs.insert(exerciseID)
        }

        save()
    }

    private func load() {
        guard let data = userDefaults.data(forKey: key),
              let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            return
        }

        favoriteExerciseIDs = ids
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(favoriteExerciseIDs) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }
}
