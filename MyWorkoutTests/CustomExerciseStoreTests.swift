import XCTest
@testable import MyWorkout

@MainActor
final class CustomExerciseStoreTests: XCTestCase {

    // MARK: - Create

    func testCreateAddsExercise() {
        let repository = InMemoryCustomExerciseRepository()
        let store = makeStore(
            repository: repository
        )

        let exercise = makeExercise(
            name: "Custom Press"
        )

        let result = store.create(
            exercise
        )

        XCTAssertTrue(result)
        XCTAssertEqual(
            store.allExercises.map { $0.id },
            [exercise.id]
        )
    }

    func testCreateRejectsDuplicateIdentifier() {
        let exercise = makeExercise(
            name: "Custom Press"
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                makeStoredExercise(
                    exercise: exercise
                )
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let result = store.create(
            exercise
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            store.allExercises.count,
            1
        )
    }

    func testCreateRejectsBuiltInName() {
        let builtInExercise = makeExercise(
            name: "Bench Press"
        )

        let store = makeStore(
            reservedExercises: [
                builtInExercise
            ]
        )

        let result = store.create(
            makeExercise(
                name: "bench press"
            )
        )

        XCTAssertFalse(result)
        XCTAssertTrue(
            store.allExercises.isEmpty
        )
    }

    func testCreateRejectsArchivedCustomExerciseName() {
        let archivedExercise = makeExercise(
            name: "Custom Press"
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                makeStoredExercise(
                    exercise: archivedExercise,
                    isArchived: true
                )
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let result = store.create(
            makeExercise(
                name: "custom press"
            )
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            store.archivedExercises.count,
            1
        )
    }

    // MARK: - Update

    func testUpdateChangesExercise() {
        let original = makeExercise(
            name: "Original Name"
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                makeStoredExercise(
                    exercise: original
                )
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let updated = makeExercise(
            id: original.id,
            name: "Updated Name"
        )

        let result = store.update(
            updated
        )

        XCTAssertTrue(result)
        XCTAssertEqual(
            store.exercise(
                id: original.id
            )?.name,
            "Updated Name"
        )
    }

    func testUpdateAllowsExerciseToKeepItsOwnName() {
        let exercise = makeExercise(
            name: "Custom Press"
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                makeStoredExercise(
                    exercise: exercise
                )
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let result = store.update(
            exercise
        )

        XCTAssertTrue(result)
    }

    func testUpdateRejectsAnotherCustomExerciseName() {
        let first = makeExercise(
            name: "First Exercise"
        )

        let second = makeExercise(
            name: "Second Exercise"
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                makeStoredExercise(
                    exercise: first
                ),
                makeStoredExercise(
                    exercise: second,
                    isArchived: true
                )
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let renamed = makeExercise(
            id: first.id,
            name: second.name
        )

        let result = store.update(
            renamed
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            store.exercise(
                id: first.id
            )?.name,
            first.name
        )
    }

    // MARK: - Archive and Restore

    func testArchiveMovesExerciseToArchivedCollection() {
        let exercise = makeExercise(
            name: "Custom Press"
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                makeStoredExercise(
                    exercise: exercise
                )
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let result = store.archive(
            exerciseID: exercise.id
        )

        XCTAssertTrue(result)
        XCTAssertTrue(
            store.activeExercises.isEmpty
        )
        XCTAssertEqual(
            store.archivedExercises.map { $0.id },
            [exercise.id]
        )
    }

    func testRestoreMovesExerciseToActiveCollection() {
        let exercise = makeExercise(
            name: "Custom Press"
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                makeStoredExercise(
                    exercise: exercise,
                    isArchived: true
                )
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let result = store.restore(
            exerciseID: exercise.id
        )

        XCTAssertTrue(result)
        XCTAssertEqual(
            store.activeExercises.map { $0.id },
            [exercise.id]
        )
        XCTAssertTrue(
            store.archivedExercises.isEmpty
        )
    }

    // MARK: - Permanent Deletion

    func testPermanentDeleteRemovesArchivedExercise() {
        let exercise = makeExercise(
            name: "Custom Press"
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                makeStoredExercise(
                    exercise: exercise,
                    isArchived: true
                )
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let result = store.permanentlyDelete(
            exerciseID: exercise.id
        )

        XCTAssertTrue(result)
        XCTAssertTrue(
            store.allExercises.isEmpty
        )
    }

    func testPermanentDeleteRejectsActiveExercise() {
        let exercise = makeExercise(
            name: "Custom Press"
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                makeStoredExercise(
                    exercise: exercise
                )
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let result = store.permanentlyDelete(
            exerciseID: exercise.id
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            store.activeExercises.map { $0.id },
            [exercise.id]
        )
    }

    // MARK: - Backup Replacement

    func testReplaceAllAcceptsValidExercises() {
        let repository = InMemoryCustomExerciseRepository()
        let store = makeStore(
            repository: repository
        )

        let first = makeStoredExercise(
            exercise: makeExercise(
                name: "Custom Press"
            )
        )

        let second = makeStoredExercise(
            exercise: makeExercise(
                name: "Custom Row"
            ),
            isArchived: true
        )

        let result = store.replaceAll(
            with: [
                second,
                first
            ]
        )

        XCTAssertTrue(result)
        XCTAssertEqual(
            store.storedExercises.map { $0.id },
            [
                first.id,
                second.id
            ]
        )
        XCTAssertEqual(
            repository.savedExercises.map { $0.id },
            [
                first.id,
                second.id
            ]
        )
        XCTAssertEqual(
            repository.saveCallCount,
            1
        )
    }

    func testReplaceAllRejectsDuplicateIdentifiers() {
        let existing = makeStoredExercise(
            exercise: makeExercise(
                name: "Existing Exercise"
            )
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                existing
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let sharedID = UUID()

        let result = store.replaceAll(
            with: [
                makeStoredExercise(
                    exercise: makeExercise(
                        id: sharedID,
                        name: "Custom Press"
                    )
                ),
                makeStoredExercise(
                    exercise: makeExercise(
                        id: sharedID,
                        name: "Custom Row"
                    )
                )
            ]
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            store.storedExercises.map { $0.id },
            [existing.id]
        )
        XCTAssertEqual(
            repository.savedExercises.map { $0.id },
            [existing.id]
        )
        XCTAssertEqual(
            repository.saveCallCount,
            0
        )
        XCTAssertNotNil(
            store.persistenceError
        )
    }

    func testReplaceAllRejectsDuplicateNames() {
        let existing = makeStoredExercise(
            exercise: makeExercise(
                name: "Existing Exercise"
            )
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                existing
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let result = store.replaceAll(
            with: [
                makeStoredExercise(
                    exercise: makeExercise(
                        name: "Custom Press"
                    )
                ),
                makeStoredExercise(
                    exercise: makeExercise(
                        name: "custom press"
                    )
                )
            ]
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            store.storedExercises.map { $0.id },
            [existing.id]
        )
        XCTAssertEqual(
            repository.savedExercises.map { $0.id },
            [existing.id]
        )
        XCTAssertEqual(
            repository.saveCallCount,
            0
        )
        XCTAssertNotNil(
            store.persistenceError
        )
    }

    func testReplaceAllRejectsReservedName() {
        let reservedExercise = makeExercise(
            name: "Bench Press"
        )

        let existing = makeStoredExercise(
            exercise: makeExercise(
                name: "Existing Exercise"
            )
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                existing
            ]
        )

        let store = makeStore(
            repository: repository,
            reservedExercises: [
                reservedExercise
            ]
        )

        let result = store.replaceAll(
            with: [
                makeStoredExercise(
                    exercise: makeExercise(
                        name: "bench press"
                    )
                )
            ]
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            store.storedExercises.map { $0.id },
            [existing.id]
        )
        XCTAssertEqual(
            repository.savedExercises.map { $0.id },
            [existing.id]
        )
        XCTAssertEqual(
            repository.saveCallCount,
            0
        )
        XCTAssertNotNil(
            store.persistenceError
        )
    }

    func testReplaceAllRejectsInvalidName() {
        let existing = makeStoredExercise(
            exercise: makeExercise(
                name: "Existing Exercise"
            )
        )

        let repository = InMemoryCustomExerciseRepository(
            storedExercises: [
                existing
            ]
        )

        let store = makeStore(
            repository: repository
        )

        let result = store.replaceAll(
            with: [
                makeStoredExercise(
                    exercise: makeExercise(
                        name: "   "
                    )
                )
            ]
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            store.storedExercises.map { $0.id },
            [existing.id]
        )
        XCTAssertEqual(
            repository.savedExercises.map { $0.id },
            [existing.id]
        )
        XCTAssertEqual(
            repository.saveCallCount,
            0
        )
        XCTAssertNotNil(
            store.persistenceError
        )
    }

    // MARK: - Fixtures

    private func makeStore(
        repository:
            InMemoryCustomExerciseRepository =
                InMemoryCustomExerciseRepository(),
        reservedExercises: [Exercise] = []
    ) -> CustomExerciseStore {
        CustomExerciseStore(
            repository: repository,
            reservedExercises: reservedExercises
        )
    }

    private func makeExercise(
        id: UUID = UUID(),
        name: String
    ) -> Exercise {
        Exercise(
            id: id,
            name: name,
            muscleGroup: .chest,
            equipment: .barbell,
            instructions: "",
            primaryMuscles: [],
            secondaryMuscles: [],
            difficulty: "Beginner",
            tips: [],
            commonMistakes: [],
            warnings: [],
            progressionRule: ProgressionRule(
                minReps: 8,
                maxReps: 12,
                increaseAmount: 5,
                deloadAmount: 10,
                stallLimit: 3
            ),
            exerciseType: .compound,
            progressionStrategy:
                .doubleProgression
        )
    }

    private func makeStoredExercise(
        exercise: Exercise,
        isArchived: Bool = false
    ) -> StoredCustomExercise {
        StoredCustomExercise(
            exercise: exercise,
            isArchived: isArchived,
            createdAt: Date(
                timeIntervalSince1970: 1
            ),
            updatedAt: Date(
                timeIntervalSince1970: 1
            )
        )
    }
}

private final class InMemoryCustomExerciseRepository:
    CustomExerciseRepository {

    private(set)
    var savedExercises: [StoredCustomExercise]

    private(set)
    var saveCallCount = 0

    init(
        storedExercises:
            [StoredCustomExercise] = []
    ) {
        savedExercises = storedExercises
    }

    func load() throws
        -> [StoredCustomExercise] {
        savedExercises
    }

    func save(
        _ exercises:
            [StoredCustomExercise]
    ) throws {
        saveCallCount += 1
        savedExercises = exercises
    }
}
