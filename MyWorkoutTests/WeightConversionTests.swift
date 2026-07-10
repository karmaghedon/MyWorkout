import XCTest
@testable import MyWorkout

final class WeightConversionTests: XCTestCase {

    func testPoundsDisplayWeightKeepsPounds() {
        let value = WeightConversion.displayWeight(fromStoredPounds: 100, unitSystem: .pounds)

        XCTAssertEqual(value, 100)
    }

    func testKilogramsDisplayWeightConvertsFromStoredPounds() {
        let value = WeightConversion.displayWeight(fromStoredPounds: 100, unitSystem: .kilograms)

        XCTAssertEqual(value, 45.4, accuracy: 0.1)
    }

    func testPoundsInputStoresAsPounds() {
        let value = WeightConversion.storedPounds(fromDisplayedWeight: 100, unitSystem: .pounds)

        XCTAssertEqual(value, 100)
    }

    func testKilogramsInputStoresAsPounds() {
        let value = WeightConversion.storedPounds(fromDisplayedWeight: 45.4, unitSystem: .kilograms)

        XCTAssertEqual(value, 100.1, accuracy: 0.2)
    }

    func testRoundTripPoundsToKilogramsBackToPounds() {
        let displayedKg = WeightConversion.displayWeight(fromStoredPounds: 135, unitSystem: .kilograms)
        let storedPounds = WeightConversion.storedPounds(fromDisplayedWeight: displayedKg, unitSystem: .kilograms)

        XCTAssertEqual(storedPounds, 135, accuracy: 0.2)
    }

    func testDisplayStepConvertsFivePoundsToKilograms() {
        let step = WeightConversion.displayStep(fromStoredPounds: 5, unitSystem: .kilograms)

        XCTAssertEqual(step, 2.3, accuracy: 0.1)
    }
}
