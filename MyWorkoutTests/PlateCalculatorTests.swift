import XCTest
@testable import MyWorkout

final class PlateCalculatorTests: XCTestCase {

    // MARK: - Exact Loading

    func testExactMatchUsesLargestAvailablePlate() {
        let loading = PlateCalculator.loading(
            for: 135,
            inventory: inventory()
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [45]
        )
        XCTAssertEqual(
            loading.achievedWeight,
            135
        )
        XCTAssertFalse(
            loading.hasResidue
        )
    }

    func testExactCombinationUsesMultiplePlateSizes() {
        let loading = PlateCalculator.loading(
            for: 205,
            inventory: inventory()
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [45, 25, 10]
        )
        XCTAssertEqual(
            loading.achievedWeight,
            205
        )
        XCTAssertFalse(
            loading.hasResidue
        )
    }

    func testNonCanonicalInventoryFindsExactCombinationGreedyWouldMiss() {
        let customInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 25,
                    quantity: 2
                ),
                PlateInventory(
                    weight: 10,
                    quantity: 6
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 105,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [10, 10, 10]
        )
        XCTAssertEqual(
            loading.achievedWeight,
            105
        )
        XCTAssertFalse(
            loading.hasResidue
        )
    }

    func testEquivalentExactLoadsPreferFewerPlates() {
        let customInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 20,
                    quantity: 2
                ),
                PlateInventory(
                    weight: 10,
                    quantity: 4
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 85,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [20]
        )
        XCTAssertFalse(
            loading.hasResidue
        )
    }

    func testEquivalentPlateCountsPreferHeavierPlatesFirst() {
        let customInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 15,
                    quantity: 2
                ),
                PlateInventory(
                    weight: 10,
                    quantity: 2
                ),
                PlateInventory(
                    weight: 5,
                    quantity: 2
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 75,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [15]
        )
    }

    // MARK: - Residue

    func testInsufficientPlatesReportsResidue() {
        let limitedInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 45,
                    quantity: 2
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 405,
            inventory: limitedInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [45]
        )
        XCTAssertEqual(
            loading.achievedWeight,
            135
        )
        XCTAssertTrue(
            loading.hasResidue
        )
    }

    func testUnreachableTargetChoosesClosestWeightWithoutExceedingTarget() {
        let customInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 25,
                    quantity: 2
                ),
                PlateInventory(
                    weight: 10,
                    quantity: 2
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 115,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [25, 10]
        )
        XCTAssertEqual(
            loading.achievedWeight,
            115
        )
        XCTAssertFalse(
            loading.hasResidue
        )
    }

    func testUnreachableTargetNeverLoadsAboveRequestedWeight() {
        let customInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 25,
                    quantity: 2
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 100,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [25]
        )
        XCTAssertEqual(
            loading.achievedWeight,
            95
        )
        XCTAssertLessThanOrEqual(
            loading.achievedWeight,
            loading.totalWeight
        )
        XCTAssertTrue(
            loading.hasResidue
        )
    }

    // MARK: - Bar-Only Loading

    func testWeightEqualToBarReturnsEmptyBar() {
        let loading = PlateCalculator.loading(
            for: 45,
            inventory: inventory()
        )

        XCTAssertTrue(
            loading.platesPerSide.isEmpty
        )
        XCTAssertEqual(
            loading.achievedWeight,
            45
        )
        XCTAssertEqual(
            loading.displayText(in: .pounds),
            "empty bar"
        )
    }

    func testWeightBelowBarReturnsEmptyBarWithoutCrashing() {
        let loading = PlateCalculator.loading(
            for: 20,
            inventory: inventory()
        )

        XCTAssertTrue(
            loading.platesPerSide.isEmpty
        )
        XCTAssertEqual(
            loading.achievedWeight,
            45
        )
    }

    func testZeroTargetReturnsEmptyBar() {
        let loading = PlateCalculator.loading(
            for: 0,
            inventory: inventory()
        )

        XCTAssertTrue(
            loading.platesPerSide.isEmpty
        )
        XCTAssertEqual(
            loading.achievedWeight,
            45
        )
    }

    func testNegativeTargetReturnsEmptyBar() {
        let loading = PlateCalculator.loading(
            for: -100,
            inventory: inventory()
        )

        XCTAssertTrue(
            loading.platesPerSide.isEmpty
        )
        XCTAssertEqual(
            loading.achievedWeight,
            45
        )
    }

    func testNoPlatesReturnsBarOnly() {
        let loading = PlateCalculator.loading(
            for: 225,
            inventory: inventory(
                plates: []
            )
        )

        XCTAssertTrue(
            loading.platesPerSide.isEmpty
        )
        XCTAssertEqual(
            loading.achievedWeight,
            45
        )
        XCTAssertTrue(
            loading.hasResidue
        )
    }

    // MARK: - Inventory Constraints

    func testOddPlateQuantityRoundsDownToCompletePairs() {
        let limitedInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 45,
                    quantity: 3
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 225,
            inventory: limitedInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [45]
        )
        XCTAssertTrue(
            loading.hasResidue
        )
    }

    func testZeroQuantityPlateIsIgnored() {
        let customInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 45,
                    quantity: 0
                ),
                PlateInventory(
                    weight: 25,
                    quantity: 2
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 95,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [25]
        )
    }

    func testNegativeQuantityPlateIsIgnored() {
        let customInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 45,
                    quantity: -2
                ),
                PlateInventory(
                    weight: 25,
                    quantity: 2
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 95,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [25]
        )
    }

    func testZeroWeightPlateIsIgnored() {
        let customInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 0,
                    quantity: 20
                ),
                PlateInventory(
                    weight: 25,
                    quantity: 2
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 95,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [25]
        )
    }

    func testResultNeverUsesMoreThanAvailablePairs() {
        let customInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 10,
                    quantity: 4
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 105,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [10, 10]
        )
        XCTAssertEqual(
            loading.achievedWeight,
            85
        )
        XCTAssertTrue(
            loading.hasResidue
        )
    }

    // MARK: - Unit Conversion

    func testKilogramInventoryConvertsToPoundsForCalculation() {
        let barWeight = WeightConversion.toPounds(
            20,
            from: .kilograms
        )

        let plateWeight = WeightConversion.toPounds(
            20,
            from: .kilograms
        )

        let totalWeight =
            barWeight + plateWeight * 2

        let loading = PlateCalculator.loading(
            for: totalWeight,
            inventory: inventory(
                barbellWeight: 20,
                plates: [
                    PlateInventory(
                        weight: 20,
                        quantity: 2
                    )
                ],
                unitSystem: .kilograms
            )
        )

        XCTAssertEqual(
            loading.platesPerSide.count,
            1
        )
        XCTAssertEqual(
            loading.platesPerSide[0],
            plateWeight,
            accuracy: 0.001
        )
        XCTAssertEqual(
            loading.achievedWeight,
            totalWeight,
            accuracy: 0.01
        )
        XCTAssertFalse(
            loading.hasResidue
        )
    }

    func testCustomBarbellWeightIsUsed() {
        let customInventory = inventory(
            barbellWeight: 35,
            plates: [
                PlateInventory(
                    weight: 25,
                    quantity: 2
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 85,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [25]
        )
        XCTAssertEqual(
            loading.achievedWeight,
            85
        )
    }

    func testFractionalPlatesCanProduceExactLoading() {
        let customInventory = inventory(
            plates: [
                PlateInventory(
                    weight: 2.5,
                    quantity: 2
                )
            ]
        )

        let loading = PlateCalculator.loading(
            for: 50,
            inventory: customInventory
        )

        XCTAssertEqual(
            loading.platesPerSide,
            [2.5]
        )
        XCTAssertEqual(
            loading.achievedWeight,
            50
        )
        XCTAssertFalse(
            loading.hasResidue
        )
    }

    // MARK: - Display

    func testDisplayTextListsPlatesPerSide() {
        let loading = PlateCalculator.loading(
            for: 205,
            inventory: inventory()
        )

        XCTAssertEqual(
            loading.displayText(in: .pounds),
            "45 + 25 + 10"
        )
    }

    // MARK: - Fixtures

    private func inventory(
        barbellWeight: Double = 45,
        plates: [PlateInventory] = [
            PlateInventory(
                weight: 45,
                quantity: 4
            ),
            PlateInventory(
                weight: 25,
                quantity: 4
            ),
            PlateInventory(
                weight: 10,
                quantity: 4
            ),
            PlateInventory(
                weight: 5,
                quantity: 4
            ),
            PlateInventory(
                weight: 2.5,
                quantity: 4
            )
        ],
        unitSystem: UnitSystem = .pounds
    ) -> EquipmentInventory {
        EquipmentInventory(
            unitSystem: unitSystem,
            barbellWeight: barbellWeight,
            plates: plates,
            dumbbells: []
        )
    }
}
