import XCTest
@testable import MyWorkout

final class InputValidationTests: XCTestCase {

    // MARK: - Weight Validation

    func test_validateWeight_acceptsZero() {
        XCTAssertEqual(InputValidation.validateWeight(0), 0)
    }

    func test_validateWeight_acceptsValidPositiveWeight() {
        XCTAssertEqual(InputValidation.validateWeight(135), 135)
        XCTAssertEqual(InputValidation.validateWeight(225.5), 225.5)
    }

    func test_validateWeight_rejectsNegativeWeight() {
        XCTAssertNil(InputValidation.validateWeight(-10))
    }

    func test_validateWeight_rejectsExcessiveWeight() {
        XCTAssertNil(InputValidation.validateWeight(10001))
    }

    func test_clampWeight_clampsNegativeToZero() {
        XCTAssertEqual(InputValidation.clampWeight(-50), 0)
    }

    func test_clampWeight_clampsExcessiveToMax() {
        XCTAssertEqual(InputValidation.clampWeight(15000), 10000)
    }

    func test_clampWeight_preservesValidWeight() {
        XCTAssertEqual(InputValidation.clampWeight(225), 225)
    }

    // MARK: - Rep Validation

    func test_validateReps_acceptsValidPositiveReps() {
        XCTAssertEqual(InputValidation.validateReps(1), 1)
        XCTAssertEqual(InputValidation.validateReps(10), 10)
        XCTAssertEqual(InputValidation.validateReps(100), 100)
    }

    func test_validateReps_rejectsZero() {
        XCTAssertNil(InputValidation.validateReps(0))
    }

    func test_validateReps_rejectsNegative() {
        XCTAssertNil(InputValidation.validateReps(-5))
    }

    func test_validateReps_rejectsExcessiveReps() {
        XCTAssertNil(InputValidation.validateReps(1001))
    }

    func test_clampReps_clampsZeroToOne() {
        XCTAssertEqual(InputValidation.clampReps(0), 1)
    }

    func test_clampReps_clampsNegativeToOne() {
        XCTAssertEqual(InputValidation.clampReps(-10), 1)
    }

    func test_clampReps_clampsExcessiveToMax() {
        XCTAssertEqual(InputValidation.clampReps(2000), 1000)
    }

    func test_clampReps_preservesValidReps() {
        XCTAssertEqual(InputValidation.clampReps(10), 10)
    }

    // MARK: - Name Validation

    func test_validateName_acceptsValidName() {
        XCTAssertEqual(InputValidation.validateName("Bench Press"), "Bench Press")
    }

    func test_validateName_trimsWhitespace() {
        XCTAssertEqual(InputValidation.validateName("  Push Day  "), "Push Day")
    }

    func test_validateName_rejectsEmptyString() {
        XCTAssertNil(InputValidation.validateName(""))
    }

    func test_validateName_rejectsWhitespaceOnly() {
        XCTAssertNil(InputValidation.validateName("   "))
    }

    func test_validateName_rejectsExcessivelyLongName() {
        let longName = String(repeating: "a", count: 101)
        XCTAssertNil(InputValidation.validateName(longName))
    }

    func test_validateName_acceptsMaxLengthName() {
        let maxName = String(repeating: "a", count: 100)
        XCTAssertEqual(InputValidation.validateName(maxName), maxName)
    }

    func test_isValidName_returnsTrueForValidName() {
        XCTAssertTrue(InputValidation.isValidName("Squat"))
    }

    func test_isValidName_returnsFalseForInvalidName() {
        XCTAssertFalse(InputValidation.isValidName(""))
        XCTAssertFalse(InputValidation.isValidName("   "))
    }

    // MARK: - Rest Duration Validation

    func test_validateRestDuration_acceptsValidDuration() {
        XCTAssertEqual(InputValidation.validateRestDuration(60), 60)
        XCTAssertEqual(InputValidation.validateRestDuration(180), 180)
    }

    func test_validateRestDuration_rejectsTooShort() {
        XCTAssertNil(InputValidation.validateRestDuration(5))
    }

    func test_validateRestDuration_rejectsTooLong() {
        XCTAssertNil(InputValidation.validateRestDuration(700))
    }

    func test_validateRestDuration_acceptsMinimum() {
        XCTAssertEqual(InputValidation.validateRestDuration(10), 10)
    }

    func test_validateRestDuration_acceptsMaximum() {
        XCTAssertEqual(InputValidation.validateRestDuration(600), 600)
    }

    func test_clampRestDuration_clampsToMinimum() {
        XCTAssertEqual(InputValidation.clampRestDuration(5), 10)
    }

    func test_clampRestDuration_clampsToMaximum() {
        XCTAssertEqual(InputValidation.clampRestDuration(700), 600)
    }

    func test_clampRestDuration_preservesValidDuration() {
        XCTAssertEqual(InputValidation.clampRestDuration(120), 120)
    }

    // MARK: - Quantity Validation

    func test_validateQuantity_acceptsZero() {
        XCTAssertEqual(InputValidation.validateQuantity(0), 0)
    }

    func test_validateQuantity_acceptsValidQuantity() {
        XCTAssertEqual(InputValidation.validateQuantity(10), 10)
    }

    func test_validateQuantity_rejectsNegative() {
        XCTAssertNil(InputValidation.validateQuantity(-1))
    }

    func test_validateQuantity_rejectsExcessive() {
        XCTAssertNil(InputValidation.validateQuantity(101))
    }

    func test_clampQuantity_clampsNegativeToZero() {
        XCTAssertEqual(InputValidation.clampQuantity(-10), 0)
    }

    func test_clampQuantity_clampsExcessiveToMax() {
        XCTAssertEqual(InputValidation.clampQuantity(200), 100)
    }

    func test_clampQuantity_preservesValidQuantity() {
        XCTAssertEqual(InputValidation.clampQuantity(50), 50)
    }
}
