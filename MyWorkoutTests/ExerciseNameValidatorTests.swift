import XCTest
@testable import MyWorkout

final class ExerciseNameValidatorTests: XCTestCase {

    // MARK: - Empty Name

    func testEmptyNameIsRejected() {
        let result = ExerciseNameValidator.validate(
            "   ",
            existingExercises: []
        )

        XCTAssertEqual(
            result,
            .empty
        )
    }

    // MARK: - Unique Name

    func testUniqueNameIsValid() {
        let result = ExerciseNameValidator.validate(
            "Incline Cable Press",
            existingExercises: []
        )

        XCTAssertEqual(
            result,
            .valid
        )
    }

    // MARK: - Duplicate Detection

    func testDuplicateNameIgnoringCaseIsRejected() {
        let exercise = makeExercise(
            name: "Bench Press"
        )

        let result = ExerciseNameValidator.validate(
            "bench press",
            existingExercises: [exercise]
        )

        XCTAssertEqual(
            result,
            .duplicate
        )
    }

    func testDuplicateNameIgnoringOuterWhitespaceIsRejected() {
        let exercise = makeExercise(
            name: "Bench Press"
        )

        let result = ExerciseNameValidator.validate(
            "  Bench Press  ",
            existingExercises: [exercise]
        )

        XCTAssertEqual(
            result,
            .duplicate
        )
    }

    func testDuplicateNameIgnoringRepeatedWhitespaceIsRejected() {
        let exercise = makeExercise(
            name: "Bench Press"
        )

        let result = ExerciseNameValidator.validate(
            "Bench   Press",
            existingExercises: [exercise]
        )

        XCTAssertEqual(
            result,
            .duplicate
        )
    }

    func testDuplicateNameIgnoringDiacriticsIsRejected() {
        let exercise = makeExercise(
            name: "Bench Press"
        )

        let result = ExerciseNameValidator.validate(
            "Bénch Press",
            existingExercises: [exercise]
        )

        XCTAssertEqual(
            result,
            .duplicate
        )
    }

    // MARK: - Editing

    func testEditedExerciseCanKeepItsCurrentName() {
        let exercise = makeExercise(
            name: "Bench Press"
        )

        let result = ExerciseNameValidator.validate(
            "Bench Press",
            existingExercises: [exercise],
            excluding: exercise.id
        )

        XCTAssertEqual(
            result,
            .valid
        )
    }

    func testEditedExerciseStillCannotUseAnotherExerciseName() {
        let editedExercise = makeExercise(
            name: "Custom Press"
        )

        let existingExercise = makeExercise(
            name: "Bench Press"
        )

        let result = ExerciseNameValidator.validate(
            "Bench Press",
            existingExercises: [
                editedExercise,
                existingExercise
            ],
            excluding: editedExercise.id
        )

        XCTAssertEqual(
            result,
            .duplicate
        )
    }

    // MARK: - Messages

    func testValidResultHasNoMessage() {
        XCTAssertNil(
            ExerciseNameValidationResult.valid.message
        )
    }

    func testEmptyResultHasExpectedMessage() {
        XCTAssertEqual(
            ExerciseNameValidationResult.empty.message,
            "Exercise name is required."
        )
    }

    func testDuplicateResultHasExpectedMessage() {
        XCTAssertEqual(
            ExerciseNameValidationResult.duplicate.message,
            "An exercise with this name already exists."
        )
    }

    // MARK: - Fixture

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
}
