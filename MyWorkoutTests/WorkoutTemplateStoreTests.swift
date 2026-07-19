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
