import XCTest
@testable import MyWorkout

final class CustomExerciseImportValidatorTests: XCTestCase {

    // MARK: - Valid Import

    func testValidateReturnsValidForUniqueCustomExercises() {
        let exercises = [
            makeStoredExercise(
                name: "Custom Chest Press"
            ),
            makeStoredExercise(
                name: "Custom Row"
            )
        ]

        let result = CustomExerciseImportValidator.validate(
            exercises,
            reservedExercises: []
        )

        XCTAssertEqual(
            result,
            .valid
        )
    }

    func testValidateReturnsValidForEmptyImport() {
        let result = CustomExerciseImportValidator.validate(
            [],
            reservedExercises: []
        )

        XCTAssertEqual(
            result,
            .valid
        )
    }

    // MARK: - Identifier Validation

    func testValidateRejectsDuplicateIdentifiers() {
        let sharedID = UUID()

        let exercises = [
            makeStoredExercise(
                id: sharedID,
                name: "Custom Press"
            ),
            makeStoredExercise(
                id: sharedID,
                name: "Custom Row"
            )
        ]

        let result = CustomExerciseImportValidator.validate(
            exercises,
            reservedExercises: []
        )

        XCTAssertEqual(
            result,
            .duplicateIdentifier
        )
    }

    func testValidateRejectsReservedIdentifier() {
        let sharedID = UUID()

        let importedExercise = makeStoredExercise(
            id: sharedID,
            name: "Custom Press"
        )

        let reservedExercise = makeExercise(
            id: sharedID,
            name: "Bench Press"
        )

        let result = CustomExerciseImportValidator.validate(
            [importedExercise],
            reservedExercises: [
                reservedExercise
            ]
        )

        XCTAssertEqual(
            result,
            .reservedIdentifier
        )
    }

    // MARK: - Name Validation

    func testValidateRejectsEmptyName() {
        let exercise = makeStoredExercise(
            name: ""
        )

        let result = CustomExerciseImportValidator.validate(
            [exercise],
            reservedExercises: []
        )

        XCTAssertEqual(
            result,
            .invalidName
        )
    }

    func testValidateRejectsWhitespaceOnlyName() {
        let exercise = makeStoredExercise(
            name: "   "
        )

        let result = CustomExerciseImportValidator.validate(
            [exercise],
            reservedExercises: []
        )

        XCTAssertEqual(
            result,
            .invalidName
        )
    }

    func testValidateRejectsDuplicateNamesIgnoringCase() {
        let exercises = [
            makeStoredExercise(
                name: "Custom Press"
            ),
            makeStoredExercise(
                name: "custom press"
            )
        ]

        let result = CustomExerciseImportValidator.validate(
            exercises,
            reservedExercises: []
        )

        XCTAssertEqual(
            result,
            .duplicateName
        )
    }

    func testValidateRejectsDuplicateNamesIgnoringSpacing() {
        let exercises = [
            makeStoredExercise(
                name: "Custom Press"
            ),
            makeStoredExercise(
                name: "  Custom Press  "
            )
        ]

        let result = CustomExerciseImportValidator.validate(
            exercises,
            reservedExercises: []
        )

        XCTAssertEqual(
            result,
            .duplicateName
        )
    }

    func testValidateRejectsReservedNameIgnoringCase() {
        let importedExercise = makeStoredExercise(
            name: "bench press"
        )

        let reservedExercise = makeExercise(
            name: "Bench Press"
        )

        let result = CustomExerciseImportValidator.validate(
            [importedExercise],
            reservedExercises: [
                reservedExercise
            ]
        )

        XCTAssertEqual(
            result,
            .reservedName
        )
    }

    // MARK: - Messages

    func testInvalidResultsProvideUserFacingMessages() {
        let invalidResults:
            [CustomExerciseImportValidationResult] = [
                .duplicateIdentifier,
                .reservedIdentifier,
                .invalidName,
                .duplicateName,
                .reservedName
            ]

        for result in invalidResults {
            XCTAssertNotNil(
                result.message
            )
            XCTAssertFalse(
                result.message?.isEmpty ?? true
            )
        }
    }

    func testValidResultDoesNotProvideErrorMessage() {
        XCTAssertNil(
            CustomExerciseImportValidationResult.valid.message
        )
    }

    // MARK: - Fixtures

    private func makeStoredExercise(
        id: UUID = UUID(),
        name: String,
        isArchived: Bool = false
    ) -> StoredCustomExercise {
        StoredCustomExercise(
            exercise: makeExercise(
                id: id,
                name: name
            ),
            isArchived: isArchived,
            createdAt: Date(
                timeIntervalSince1970: 1
            ),
            updatedAt: Date(
                timeIntervalSince1970: 1
            )
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
}
