import Foundation

/// Tracks which exercises (built-in or custom) the user has favorited.
/// Low-stakes preference data — unlike workout logs/templates/settings,
/// losing this isn't a data-loss concern worth the full corruption-
/// protection treatment those stores use, so this stays intentionally
/// simple: a single `Set<UUID>` in UserDefaults, no envelope/migration.
///
/// Keyed by `Exercise.id`, which is stable across launches for both
/// custom exercises (persisted) and built-ins (a deterministic hash of
/// the name, see `SeedData.stableID`) — and, unlike a name-based key,
/// survives a custom exercise being renamed.
@MainActor
final class FavoriteExercisesStore: ObservableObject {
    @Published private(set) var favoriteExerciseIDs: Set<UUID> = []

    private let key = "favorite_exercise_ids"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func isFavorite(_ exercise: Exercise) -> Bool {
        favoriteExerciseIDs.contains(exercise.id)
    }

    func toggleFavorite(_ exercise: Exercise) {
        if favoriteExerciseIDs.contains(exercise.id) {
            favoriteExerciseIDs.remove(exercise.id)
        } else {
            favoriteExerciseIDs.insert(exercise.id)
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
