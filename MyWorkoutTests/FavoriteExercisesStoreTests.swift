import XCTest
@testable import MyWorkout

@MainActor
final class FavoriteExercisesStoreTests: XCTestCase {

    // MARK: - Fixtures

    private func makeUserDefaults(testName: String) -> UserDefaults {
        let suiteName =
            "FavoriteExercisesStoreTests."
            + testName
            + "."
            + UUID().uuidString

        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func exercise(id: UUID = UUID(), name: String) -> Exercise {
        Exercise(
            id: id,
            name: name,
            muscleGroup: .chest,
            equipment: .barbell,
            instructions: "Push it",
            progressionRule: ProgressionRule(
                minReps: 8,
                maxReps: 12,
                increaseAmount: 5,
                deloadAmount: 10,
                stallLimit: 3
            ),
            exerciseType: .compound,
            progressionStrategy: .doubleProgression
        )
    }

    // MARK: - Basic favoriting

    func test_toggleFavorite_marksAndUnmarksExercise() {
        let store = FavoriteExercisesStore(
            userDefaults: makeUserDefaults(testName: #function)
        )
        let exercise = exercise(name: "Bench Press")

        XCTAssertFalse(store.isFavorite(exercise))

        store.toggleFavorite(exercise)
        XCTAssertTrue(store.isFavorite(exercise))

        store.toggleFavorite(exercise)
        XCTAssertFalse(store.isFavorite(exercise))
    }

    func test_favorite_persistsAcrossStoreInstances() {
        let defaults = makeUserDefaults(testName: #function)
        let exercise = exercise(name: "Bench Press")

        FavoriteExercisesStore(userDefaults: defaults)
            .toggleFavorite(exercise)

        let reloaded = FavoriteExercisesStore(userDefaults: defaults)
        XCTAssertTrue(reloaded.isFavorite(exercise))
    }

    /// Regression test: favorites are keyed by `Exercise.id`, not by name,
    /// so renaming a custom exercise (its `id` stays fixed, only `name`
    /// changes) must not un-favorite it. A name-keyed store would silently
    /// drop the favorite here, since `normalize(oldName) != normalize(newName)`.
    func test_favorite_survivesExerciseRename() {
        let defaults = makeUserDefaults(testName: #function)
        let exerciseID = UUID()
        let original = exercise(id: exerciseID, name: "My Curl")
        let renamed = exercise(id: exerciseID, name: "My Bicep Curl")

        let store = FavoriteExercisesStore(userDefaults: defaults)
        store.toggleFavorite(original)

        XCTAssertTrue(store.isFavorite(renamed))
    }
}
