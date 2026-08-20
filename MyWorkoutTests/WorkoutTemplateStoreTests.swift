import XCTest
@testable import MyWorkout

@MainActor
final class WorkoutTemplateStoreTests: XCTestCase {

    var sut: WorkoutTemplateStore!

    override func setUp() async throws {
        sut = WorkoutTemplateStore()
        // Start with clean state
        sut.templates = []
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Add

    func test_add_appendsTemplateToList() {
        let template = createSampleTemplate(name: "Push Day")

        sut.add(template)

        XCTAssertEqual(sut.templates.count, 1)
        XCTAssertEqual(sut.templates.first?.name, "Push Day")
    }

    /// Regression test: `WorkoutTemplateStore.refreshed(_:)` re-resolves
    /// every saved exercise against the current built-in definition to
    /// stay in sync with `SeedData` changes — but naively swapping in
    /// that whole fresh `Exercise` value used to silently wipe
    /// `targetSets`/`targetWeightPounds` back to their global defaults
    /// (3 / nil) on every save, since those are per-template overrides
    /// that don't exist on the built-in definition itself. Uses "Bench
    /// Press" specifically because it's a real `SeedData` entry, so
    /// `builtInRegistry.exercise(id:name:)` actually resolves it (an
    /// ad-hoc test name with no SeedData match would return nil and
    /// bypass the refresh path entirely, defeating the point of this
    /// test).
    func test_add_preservesTargetSetsAndWeightOverrideForBuiltInExercise() {
        var exercise = createSampleExercise(name: "Bench Press")
        exercise.targetSets = 5
        exercise.targetWeightPounds = 135

        let template = WorkoutTemplate(
            name: "Push Day",
            exercises: [exercise]
        )

        sut.add(template)

        let savedExercise = sut.templates.first?.exercises.first
        XCTAssertEqual(savedExercise?.targetSets, 5)
        XCTAssertEqual(savedExercise?.targetWeightPounds, 135)
    }

    func test_add_multipleTemplatesAreStored() {
        sut.add(createSampleTemplate(name: "Push"))
        sut.add(createSampleTemplate(name: "Pull"))
        sut.add(createSampleTemplate(name: "Legs"))

        XCTAssertEqual(sut.templates.count, 3)
    }

    // MARK: - Delete

    func test_delete_removesTemplateAtIndex() {
        sut.add(createSampleTemplate(name: "Template 1"))
        sut.add(createSampleTemplate(name: "Template 2"))
        sut.add(createSampleTemplate(name: "Template 3"))

        sut.delete(at: IndexSet(integer: 1))

        XCTAssertEqual(sut.templates.count, 2)
        XCTAssertEqual(sut.templates[0].name, "Template 1")
        XCTAssertEqual(sut.templates[1].name, "Template 3")
    }

    // MARK: - Update

    func test_update_replacesExistingTemplate() {
        let original = createSampleTemplate(name: "Original")
        sut.add(original)

        var updated = original
        updated.name = "Updated"

        sut.update(updated)

        XCTAssertEqual(sut.templates.count, 1)
        XCTAssertEqual(sut.templates.first?.name, "Updated")
    }

    func test_update_preservesTargetSetsAndWeightOverrideForBuiltInExercise() {
        let exercise = createSampleExercise(name: "Bench Press")
        let original = WorkoutTemplate(
            name: "Push Day",
            exercises: [exercise]
        )
        sut.add(original)

        var updatedExercise = sut.templates.first!.exercises.first!
        updatedExercise.targetSets = 4
        updatedExercise.targetWeightPounds = 185

        var updated = sut.templates.first!
        updated.exercises = [updatedExercise]
        sut.update(updated)

        let savedExercise = sut.templates.first?.exercises.first
        XCTAssertEqual(savedExercise?.targetSets, 4)
        XCTAssertEqual(savedExercise?.targetWeightPounds, 185)
    }

    func test_update_doesNothingWhenTemplateNotFound() {
        sut.add(createSampleTemplate(name: "Existing"))

        let nonExistent = createSampleTemplate(name: "Non-existent")
        sut.update(nonExistent)

        XCTAssertEqual(sut.templates.count, 1)
        XCTAssertEqual(sut.templates.first?.name, "Existing")
    }

    // MARK: - Duplicate

    func test_duplicate_createsNewTemplateWithCopySuffix() {
        let original = createSampleTemplate(name: "Push Day")
        sut.add(original)

        sut.duplicate(original)

        XCTAssertEqual(sut.templates.count, 2)
        XCTAssertEqual(sut.templates[0].name, "Push Day")
        XCTAssertEqual(sut.templates[1].name, "Push Day Copy")
    }

    func test_duplicate_copiesExercises() {
        let exercise = createSampleExercise(name: "Bench Press")
        let original = WorkoutTemplate(
            name: "Push Day",
            exercises: [exercise]
        )

        sut.add(original)
        sut.duplicate(original)

        XCTAssertEqual(sut.templates[1].exercises.count, 1)
        XCTAssertEqual(sut.templates[1].exercises.first?.name, "Bench Press")
    }

    // MARK: - Replace All

    func test_replaceAll_replacesAllTemplates() {
        sut.add(createSampleTemplate(name: "Old 1"))
        sut.add(createSampleTemplate(name: "Old 2"))

        let newTemplates = [
            createSampleTemplate(name: "New 1"),
            createSampleTemplate(name: "New 2"),
            createSampleTemplate(name: "New 3")
        ]

        sut.replaceAll(with: newTemplates)

        XCTAssertEqual(sut.templates.count, 3)
        XCTAssertEqual(sut.templates[0].name, "New 1")
        XCTAssertEqual(sut.templates[1].name, "New 2")
        XCTAssertEqual(sut.templates[2].name, "New 3")
    }

    func test_replaceAll_withEmptyArray_clearsAllTemplates() {
        sut.add(createSampleTemplate(name: "Template 1"))
        sut.add(createSampleTemplate(name: "Template 2"))

        sut.replaceAll(with: [])

        XCTAssertEqual(sut.templates.count, 0)
    }

    // MARK: - Helper Methods

    private func createSampleTemplate(name: String) -> WorkoutTemplate {
        WorkoutTemplate(
            name: name,
            exercises: []
        )
    }

    private func createSampleExercise(name: String) -> Exercise {
        Exercise(
            name: name,
            muscleGroup: .chest,
            equipment: .barbell,
            instructions: "Test",
            progressionRule: ProgressionRule(minReps: 5, maxReps: 10, increaseAmount: 5, deloadAmount: 5, stallLimit: 3),
            exerciseType: .compound,
            progressionStrategy: .doubleProgression
        )
    }
}
