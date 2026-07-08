import XCTest
@testable import MyWorkout

final class WeightConversionTests: XCTestCase {

    func test_toPounds_pounds_isIdentity() {
        XCTAssertEqual(WeightConversion.toPounds(135, from: .pounds), 135)
    }

    func test_toPounds_kilograms_convertsCorrectly() {
        // 100 kg ≈ 220.46 lb
        XCTAssertEqual(WeightConversion.toPounds(100, from: .kilograms), 220.46, accuracy: 0.01)
    }

    func test_fromPounds_pounds_isIdentity() {
        XCTAssertEqual(WeightConversion.fromPounds(135, to: .pounds), 135)
    }

    func test_fromPounds_kilograms_convertsCorrectly() {
        // 220.46 lb ≈ 100 kg
        XCTAssertEqual(WeightConversion.fromPounds(220.46, to: .kilograms), 100, accuracy: 0.01)
    }

    func test_zeroWeight_convertsToZeroInBothDirections() {
        XCTAssertEqual(WeightConversion.toPounds(0, from: .kilograms), 0)
        XCTAssertEqual(WeightConversion.fromPounds(0, to: .kilograms), 0)
    }

    func test_roundTrip_kilogramsToPoundsAndBack_preservesOriginalValue() {
        let original = 62.5
        let pounds = WeightConversion.toPounds(original, from: .kilograms)
        let roundTripped = WeightConversion.fromPounds(pounds, to: .kilograms)

        XCTAssertEqual(roundTripped, original, accuracy: 0.0001)
    }

    func test_roundTrip_poundsToKilogramsAndBack_preservesOriginalValue() {
        let original = 135.0
        let kilograms = WeightConversion.fromPounds(original, to: .kilograms)
        let roundTripped = WeightConversion.toPounds(kilograms, from: .kilograms)

        XCTAssertEqual(roundTripped, original, accuracy: 0.0001)
    }
}
