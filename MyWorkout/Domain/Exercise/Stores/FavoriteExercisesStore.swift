import Foundation

/// Tracks which exercises (built-in or custom) the user has favorited.
/// Low-stakes preference data — unlike workout logs/templates/settings,
/// losing this isn't a data-loss concern worth the full corruption-
/// protection treatment those stores use, so this stays intentionally
/// simple: a single `Set<String>` in UserDefaults, no envelope/migration.
///
/// Keyed by normalized exercise name, not `Exercise.id`. Built-in
/// exercises get a fresh random `id` every app launch (`SeedData` never
/// passes one explicitly), so persisting favorites by ID would silently
/// lose every built-in favorite on relaunch — the persisted UUID would
/// never match any current exercise's `id` again. Normalized name is
/// stable across launches and, per `ExerciseNameValidator`, already
/// guaranteed unique across built-in and custom exercises alike.
@MainActor
final class FavoriteExercisesStore: ObservableObject {
    @Published private(set) var favoriteExerciseKeys: Set<String> = []

    private let key = "favorite_exercise_keys"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func isFavorite(_ exercise: Exercise) -> Bool {
        favoriteExerciseKeys.contains(
            ExerciseNameValidator.normalize(exercise.name)
        )
    }

    func toggleFavorite(_ exercise: Exercise) {
        let normalizedName = ExerciseNameValidator.normalize(exercise.name)

        if favoriteExerciseKeys.contains(normalizedName) {
            favoriteExerciseKeys.remove(normalizedName)
        } else {
            favoriteExerciseKeys.insert(normalizedName)
        }

        save()
    }

    private func load() {
        guard let data = userDefaults.data(forKey: key),
              let keys = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return
        }

        favoriteExerciseKeys = keys
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(favoriteExerciseKeys) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }
}
