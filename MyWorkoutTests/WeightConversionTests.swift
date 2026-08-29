import XCTest
@testable import MyWorkout

final class WeightConversionTests: XCTestCase {

    // MARK: - Base Conversion

    func testKilogramsToPoundsConvertsKnownValue() {
        let pounds =
            WeightConversion.kilogramsToPounds(100)

        XCTAssertEqual(
            pounds,
            220.46226218,
            accuracy: 0.00000001
        )
    }

    func testPoundsToKilogramsConvertsKnownValue() {
        let kilograms =
            WeightConversion.poundsToKilograms(100)

        XCTAssertEqual(
            kilograms,
            45.359237,
            accuracy: 0.000001
        )
    }

    func testZeroConvertsToZeroInBothDirections() {
        XCTAssertEqual(
            WeightConversion.kilogramsToPounds(0),
            0
        )

        XCTAssertEqual(
            WeightConversion.poundsToKilograms(0),
            0
        )
    }

    func testNegativeValuesPreserveSignDuringConversion() {
        XCTAssertLessThan(
            WeightConversion.kilogramsToPounds(-10),
            0
        )

        XCTAssertLessThan(
            WeightConversion.poundsToKilograms(-10),
            0
        )
    }

    func testLargeValueConversionRemainsAccurate() {
        let kilograms =
            WeightConversion.poundsToKilograms(10_000)

        XCTAssertEqual(
            kilograms,
            4_535.9237,
            accuracy: 0.0001
        )
    }

    // MARK: - Compatibility Conversion

    func testToPoundsKeepsPoundValueUnchanged() {
        let pounds = WeightConversion.toPounds(
            135,
            from: .pounds
        )

        XCTAssertEqual(
            pounds,
            135
        )
    }

    func testToPoundsConvertsKilogramValue() {
        let pounds = WeightConversion.toPounds(
            20,
            from: .kilograms
        )

        XCTAssertEqual(
            pounds,
            WeightConversion.kilogramsToPounds(20),
            accuracy: 0.000001
        )
    }

    func testFromPoundsKeepsPoundValueUnchanged() {
        let value = WeightConversion.fromPounds(
            135,
            to: .pounds
        )

        XCTAssertEqual(
            value,
            135
        )
    }

    func testFromPoundsConvertsToKilograms() {
        let kilograms = WeightConversion.fromPounds(
            100,
            to: .kilograms
        )

        XCTAssertEqual(
            kilograms,
            45.359237,
            accuracy: 0.000001
        )
    }

    // MARK: - Display Boundary

    func testPoundsDisplayWeightKeepsStoredPounds() {
        let value = WeightConversion.displayWeight(
            fromStoredPounds: 100,
            unitSystem: .pounds
        )

        XCTAssertEqual(
            value,
            100
        )
    }

    func testKilogramsDisplayWeightRoundsToOneDecimalPlace() {
        let value = WeightConversion.displayWeight(
            fromStoredPounds: 100,
            unitSystem: .kilograms
        )

        XCTAssertEqual(
            value,
            45.4
        )
    }

    func testKilogramsDisplayWeightRoundsHalfUpAccordingToSwiftRounding() {
        let value = WeightConversion.displayWeight(
            fromStoredPounds: 45,
            unitSystem: .kilograms
        )

        XCTAssertEqual(
            value,
            20.4
        )
    }

    // MARK: - Storage Boundary

    func testPoundsInputStoresAtQuarterPoundPrecision() {
        let value = WeightConversion.storedPounds(
            fromDisplayedWeight: 100.13,
            unitSystem: .pounds
        )

        XCTAssertEqual(
            value,
            100.25
        )
    }

    func testKilogramsInputConvertsAndNormalizesToQuarterPound() {
        let value = WeightConversion.storedPounds(
            fromDisplayedWeight: 45.4,
            unitSystem: .kilograms
        )

        XCTAssertEqual(
            value,
            100,
            accuracy: 0.25
        )

        XCTAssertEqual(
            value.truncatingRemainder(
                dividingBy: 0.25
            ),
            0,
            accuracy: 0.000001
        )
    }

    func testStoredPoundsPreservesZero() {
        XCTAssertEqual(
            WeightConversion.storedPounds(
                fromDisplayedWeight: 0,
                unitSystem: .pounds
            ),
            0
        )

        XCTAssertEqual(
            WeightConversion.storedPounds(
                fromDisplayedWeight: 0,
                unitSystem: .kilograms
            ),
            0
        )
    }

    func testStoredPoundsPreservesNegativeSign() {
        let stored = WeightConversion.storedPounds(
            fromDisplayedWeight: -10,
            unitSystem: .kilograms
        )

        XCTAssertLessThan(
            stored,
            0
        )
    }

    // MARK: - Round-Trip Stability

    func testPoundsToKilogramsAndBackReturnsApproximatelyOriginalWeight() {
        let displayedKilograms =
            WeightConversion.displayWeight(
                fromStoredPounds: 135,
                unitSystem: .kilograms
            )

        let storedPounds =
            WeightConversion.storedPounds(
                fromDisplayedWeight: displayedKilograms,
                unitSystem: .kilograms
            )

        XCTAssertEqual(
            storedPounds,
            135,
            accuracy: 0.25
        )
    }

    func testRepeatedUnitRoundTripsDoNotAccumulateDrift() {
        var storedPounds = 135.25

        for _ in 0..<20 {
            let displayedKilograms =
                WeightConversion.displayWeight(
                    fromStoredPounds: storedPounds,
                    unitSystem: .kilograms
                )

            storedPounds =
                WeightConversion.storedPounds(
                    fromDisplayedWeight: displayedKilograms,
                    unitSystem: .kilograms
                )
        }

        XCTAssertEqual(
            storedPounds,
            135.25,
            accuracy: 0.25
        )
    }

    func testRepresentativeStoredWeightsRemainStableAcrossRoundTrip() {
        let storedWeights: [Double] = [
            0,
            2.5,
            45,
            100,
            135.25,
            225,
            500
        ]

        for originalWeight in storedWeights {
            let displayedKilograms =
                WeightConversion.displayWeight(
                    fromStoredPounds: originalWeight,
                    unitSystem: .kilograms
                )

            let restoredWeight =
                WeightConversion.storedPounds(
                    fromDisplayedWeight: displayedKilograms,
                    unitSystem: .kilograms
                )

            XCTAssertEqual(
                restoredWeight,
                originalWeight,
                accuracy: 0.25,
                "Round trip changed \(originalWeight) lb"
            )
        }
    }

    // MARK: - Display Step

    func testPoundDisplayStepKeepsStoredIncrement() {
        let step = WeightConversion.displayStep(
            fromStoredPounds: 5,
            unitSystem: .pounds
        )

        XCTAssertEqual(
            step,
            5
        )
    }

    func testFivePoundStepDisplaysAsTwoPointFiveKilograms() {
        let step = WeightConversion.displayStep(
            fromStoredPounds: 5,
            unitSystem: .kilograms
        )

        XCTAssertEqual(
            step,
            2.5
        )
    }

    func testKilogramDisplayStepUsesMinimumHalfKilogramIncrement() {
        let step = WeightConversion.displayStep(
            fromStoredPounds: 0.25,
            unitSystem: .kilograms
        )

        XCTAssertEqual(
            step,
            0.5
        )
    }

    func testTenPoundStepDisplaysAsFourPointFiveKilograms() {
        let step = WeightConversion.displayStep(
            fromStoredPounds: 10,
            unitSystem: .kilograms
        )

        XCTAssertEqual(
            step,
            4.5
        )
    }

    // MARK: - Rounding Helpers

    func testRoundToDecimalPlacesRoundsToRequestedPrecision() {
        XCTAssertEqual(
            WeightConversion.roundToDecimalPlaces(
                45.359237,
                places: 1
            ),
            45.4
        )

        XCTAssertEqual(
            WeightConversion.roundToDecimalPlaces(
                45.359237,
                places: 2
            ),
            45.36
        )
    }

    func testRoundToNearestRoundsToRequestedStep() {
        XCTAssertEqual(
            WeightConversion.roundToNearest(
                100.13,
                step: 0.25
            ),
            100.25
        )

        XCTAssertEqual(
            WeightConversion.roundToNearest(
                2.26796,
                step: 0.5
            ),
            2.5
        )
    }

    func testRoundToNearestWithInvalidStepReturnsOriginalValue() {
        XCTAssertEqual(
            WeightConversion.roundToNearest(
                12.34,
                step: 0
            ),
            12.34
        )

        XCTAssertEqual(
            WeightConversion.roundToNearest(
                12.34,
                step: -1
            ),
            12.34
        )
    }
}
