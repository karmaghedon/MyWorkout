import XCTest
@testable import MyWorkout

final class PlateCalculatorTests: XCTestCase {

    private func inventory(
        barbellWeight: Double = 45,
        plates: [PlateInventory] = [
            PlateInventory(weight: 45, quantity: 4),
            PlateInventory(weight: 25, quantity: 4),
            PlateInventory(weight: 10, quantity: 4),
            PlateInventory(weight: 5, quantity: 4),
            PlateInventory(weight: 2.5, quantity: 4)
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

    func test_exactMatch_usesLargestPlatesFirst() {
        let loading = PlateCalculator.loading(for: 135, inventory: inventory())

        // 135 - 45 bar = 90 total, 45 per side -> one 45 plate per side
        XCTAssertEqual(loading.platesPerSide, [45])
        XCTAssertEqual(loading.achievedWeight, 135)
        XCTAssertFalse(loading.hasResidue)
    }

    func test_combinationOfPlates_greedyFillsPerSide() {
        // 205 lb: 45 bar + 160 -> 80 per side -> 45 + 25 + 10 = 80
        let loading = PlateCalculator.loading(for: 205, inventory: inventory())

        XCTAssertEqual(loading.platesPerSide, [45, 25, 10])
        XCTAssertEqual(loading.achievedWeight, 205)
        XCTAssertFalse(loading.hasResidue)
    }

    func test_insufficientPlates_reportsResidue() {
        // Only one 45 available (quantity 2 total -> 1 per side), asking for weight
        // that would need two 45s per side.
        let limitedInventory = inventory(
            plates: [PlateInventory(weight: 45, quantity: 2)]
        )

        // 45 bar + want 180 per side (360 total) but only one 45/side available (45/side achievable)
        let loading = PlateCalculator.loading(for: 405, inventory: limitedInventory)

        XCTAssertEqual(loading.platesPerSide, [45])
        XCTAssertEqual(loading.achievedWeight, 135) // 45 bar + 45*2
        XCTAssertTrue(loading.hasResidue)
    }

    func test_weightAtOrBelowBarWeight_returnsEmptyBar() {
        let loading = PlateCalculator.loading(for: 45, inventory: inventory())

        XCTAssertEqual(loading.platesPerSide, [])
        XCTAssertEqual(loading.achievedWeight, 45)
        XCTAssertEqual(loading.displayText(in: .pounds), "empty bar")
    }

    func test_weightBelowBarWeight_returnsEmptyBarWithoutCrashing() {
        let loading = PlateCalculator.loading(for: 20, inventory: inventory())

        XCTAssertEqual(loading.platesPerSide, [])
        XCTAssertEqual(loading.achievedWeight, 45)
    }

    func test_noPlatesInInventory_returnsBarOnly() {
        let emptyInventory = inventory(plates: [])
        let loading = PlateCalculator.loading(for: 225, inventory: emptyInventory)

        XCTAssertEqual(loading.platesPerSide, [])
        XCTAssertEqual(loading.achievedWeight, 45)
        XCTAssertTrue(loading.hasResidue)
    }

    func test_oddQuantityPlates_roundDownToPairs() {
        // 3 total 45s -> only 1 pair (1 per side) usable, since plates load in pairs.
        let limitedInventory = inventory(
            plates: [PlateInventory(weight: 45, quantity: 3)]
        )
        let loading = PlateCalculator.loading(for: 225, inventory: limitedInventory)

        // 225 wants 90/side; only 1x45/side available -> residue
        XCTAssertEqual(loading.platesPerSide, [45])
        XCTAssertTrue(loading.hasResidue)
    }

    func test_kilogramInventory_convertsToPoundsForCalculation() {
        // Bar 20kg and plates 20kg are converted to pounds before matching.
        // totalWeight itself is always expressed in pounds, so request exactly
        // bar + 2 plates (in pounds) to confirm the kg->lb conversion happened
        // and one plate per side was selected.
        let barLb = WeightConversion.toPounds(20, from: .kilograms)
        let plateLb = WeightConversion.toPounds(20, from: .kilograms)
        let totalWeight = barLb + (plateLb * 2)

        let kgInventory = inventory(
            barbellWeight: 20,
            plates: [PlateInventory(weight: 20, quantity: 2)],
            unitSystem: .kilograms
        )

        let loading = PlateCalculator.loading(for: totalWeight, inventory: kgInventory)

        XCTAssertEqual(loading.platesPerSide.count, 1)
        XCTAssertFalse(loading.hasResidue)
        XCTAssertEqual(loading.achievedWeight, totalWeight, accuracy: 0.01)
    }
}
