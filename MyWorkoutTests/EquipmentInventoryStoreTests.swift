import XCTest
@testable import MyWorkout

@MainActor
final class EquipmentInventoryStoreTests:
    XCTestCase {

    // MARK: - Initialization

    func testInitializationWithoutPersistedInventoryUsesDefaultsAndSaves()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        XCTAssertEqual(
            store.inventory.unitSystem,
            .pounds
        )

        XCTAssertEqual(
            store.inventory.barbellWeight,
            EquipmentInventory
                .defaultInventory
                .barbellWeight
        )

        XCTAssertEqual(
            store.inventory.plates,
            EquipmentInventory
                .defaultInventory
                .plates
        )

        let persisted =
            try EquipmentInventoryTestSupport
                .decodeInventory(
                    from: fileURL
                )

        XCTAssertEqual(
            persisted.barbellWeight,
            EquipmentInventory
                .defaultInventory
                .barbellWeight
        )

        XCTAssertNil(
            store.persistenceError
        )
    }

    func testInitializationLoadsPersistedInventory()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let inventory =
            EquipmentInventoryTestSupport
                .makeInventory(
                    barbellWeight: 35
                )

        let data = try JSONEncoder().encode(
            inventory
        )

        try data.write(to: fileURL)

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        XCTAssertEqual(
            store.inventory.barbellWeight,
            35
        )

        XCTAssertEqual(
            store.inventory.plates,
            inventory.plates
        )

        XCTAssertEqual(
            store.inventory.dumbbells,
            inventory.dumbbells
        )

        XCTAssertNil(
            store.persistenceError
        )
    }

    func testInvalidPersistedDataRestoresDefaultsAndExposesLoadingError()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        try Data("invalid".utf8).write(to: fileURL)

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        XCTAssertEqual(
            store.inventory.barbellWeight,
            EquipmentInventory
                .defaultInventory
                .barbellWeight
        )

        XCTAssertEqual(
            store.persistenceError?.operation,
            .loading
        )

        let persisted =
            try EquipmentInventoryTestSupport
                .decodeInventory(
                    from: fileURL
                )

        XCTAssertEqual(
            persisted.plates,
            EquipmentInventory
                .defaultInventory
                .plates
        )
    }

    // MARK: - Save

    func testSavePersistsCurrentInventory()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        store.inventory.barbellWeight = 55
        store.save()

        let persisted =
            try EquipmentInventoryTestSupport
                .decodeInventory(
                    from: fileURL
                )

        XCTAssertEqual(
            persisted.barbellWeight,
            55
        )
    }

    // MARK: - Add

    func testAddPlateSortsDescendingAndPersists()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        store.replace(
            with:
                EquipmentInventoryTestSupport
                    .makeInventory(
                        plates: [
                            PlateInventory(
                                weight: 10,
                                quantity: 2
                            ),
                            PlateInventory(
                                weight: 5,
                                quantity: 2
                            )
                        ],
                        dumbbells: []
                    )
        )

        store.addPlate(
            weight: 25,
            quantity: 2
        )

        XCTAssertEqual(
            store.inventory.plates.map(\.weight),
            [25, 10, 5]
        )

        let persisted =
            try EquipmentInventoryTestSupport
                .decodeInventory(
                    from: fileURL
                )

        XCTAssertEqual(
            persisted.plates.map(\.weight),
            [25, 10, 5]
        )
    }

    func testAddDumbbellSortsAscendingAndPersists()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        store.replace(
            with:
                EquipmentInventoryTestSupport
                    .makeInventory(
                        plates: [],
                        dumbbells: [
                            DumbbellInventory(
                                weight: 20,
                                quantity: 2
                            ),
                            DumbbellInventory(
                                weight: 10,
                                quantity: 2
                            )
                        ]
                    )
        )

        store.addDumbbell(
            weight: 15,
            quantity: 2
        )

        XCTAssertEqual(
            store.inventory.dumbbells.map(\.weight),
            [10, 15, 20]
        )

        let persisted =
            try EquipmentInventoryTestSupport
                .decodeInventory(
                    from: fileURL
                )

        XCTAssertEqual(
            persisted.dumbbells.map(\.weight),
            [10, 15, 20]
        )
    }

    func testInvalidPlateInputDoesNotChangeInventory()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        let original =
            store.inventory.plates

        store.addPlate(
            weight: 0,
            quantity: 2
        )

        store.addPlate(
            weight: 10,
            quantity: 0
        )

        XCTAssertEqual(
            store.inventory.plates,
            original
        )
    }

    func testInvalidDumbbellInputDoesNotChangeInventory() {
        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        let original =
            store.inventory.dumbbells

        store.addDumbbell(
            weight: -5,
            quantity: 2
        )

        store.addDumbbell(
            weight: 20,
            quantity: -1
        )

        XCTAssertEqual(
            store.inventory.dumbbells,
            original
        )
    }

    // MARK: - Delete

    func testDeletePlateByIdentifierPersists()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let removedID = UUID()

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        store.replace(
            with:
                EquipmentInventoryTestSupport
                    .makeInventory(
                        plates: [
                            PlateInventory(
                                id: removedID,
                                weight: 25,
                                quantity: 2
                            ),
                            PlateInventory(
                                weight: 10,
                                quantity: 2
                            )
                        ],
                        dumbbells: []
                    )
        )

        store.deletePlate(
            id: removedID
        )

        XCTAssertFalse(
            store.inventory.plates.contains {
                $0.id == removedID
            }
        )

        let persisted =
            try EquipmentInventoryTestSupport
                .decodeInventory(
                    from: fileURL
                )

        XCTAssertFalse(
            persisted.plates.contains {
                $0.id == removedID
            }
        )
    }

    func testDeleteDumbbellByIdentifierPersists()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let removedID = UUID()

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        store.replace(
            with:
                EquipmentInventoryTestSupport
                    .makeInventory(
                        plates: [],
                        dumbbells: [
                            DumbbellInventory(
                                id: removedID,
                                weight: 20,
                                quantity: 2
                            ),
                            DumbbellInventory(
                                weight: 30,
                                quantity: 2
                            )
                        ]
                    )
        )

        store.deleteDumbbell(
            id: removedID
        )

        XCTAssertFalse(
            store.inventory.dumbbells.contains {
                $0.id == removedID
            }
        )

        let persisted =
            try EquipmentInventoryTestSupport
                .decodeInventory(
                    from: fileURL
                )

        XCTAssertFalse(
            persisted.dumbbells.contains {
                $0.id == removedID
            }
        )
    }

    // MARK: - Replacement

    func testReplaceSortsAndPersistsInventory()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        let replacement =
            EquipmentInventoryTestSupport
                .makeInventory(
                    plates: [
                        PlateInventory(
                            weight: 5,
                            quantity: 2
                        ),
                        PlateInventory(
                            weight: 45,
                            quantity: 2
                        ),
                        PlateInventory(
                            weight: 10,
                            quantity: 2
                        )
                    ],
                    dumbbells: [
                        DumbbellInventory(
                            weight: 30,
                            quantity: 2
                        ),
                        DumbbellInventory(
                            weight: 10,
                            quantity: 2
                        )
                    ]
                )

        store.replace(
            with: replacement
        )

        XCTAssertEqual(
            store.inventory.plates.map(\.weight),
            [45, 10, 5]
        )

        XCTAssertEqual(
            store.inventory.dumbbells.map(\.weight),
            [10, 30]
        )

        let persisted =
            try EquipmentInventoryTestSupport
                .decodeInventory(
                    from: fileURL
                )

        XCTAssertEqual(
            persisted.plates.map(\.weight),
            [45, 10, 5]
        )
    }

    // MARK: - Reset

    func testResetToDefaultInPoundsRestoresDefaults()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        store.replace(
            with:
                EquipmentInventoryTestSupport
                    .makeInventory(
                        barbellWeight: 20
                    )
        )

        store.resetToDefault(
            unit: .pounds
        )

        XCTAssertEqual(
            store.inventory.unitSystem,
            .pounds
        )

        XCTAssertEqual(
            store.inventory.barbellWeight,
            45
        )

        XCTAssertEqual(
            store.inventory.plates,
            EquipmentInventory
                .defaultInventory
                .plates
        )

        let persisted =
            try EquipmentInventoryTestSupport
                .decodeInventory(
                    from: fileURL
                )

        XCTAssertEqual(
            persisted.unitSystem,
            .pounds
        )
    }

    func testResetToDefaultInKilogramsConvertsAndPersists()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        store.resetToDefault(
            unit: .kilograms
        )

        XCTAssertEqual(
            store.inventory.unitSystem,
            .kilograms
        )

        XCTAssertEqual(
            store.inventory.barbellWeight,
            WeightConversion
                .poundsToKilograms(45),
            accuracy: 0.0001
        )

        let persisted =
            try EquipmentInventoryTestSupport
                .decodeInventory(
                    from: fileURL
                )

        XCTAssertEqual(
            persisted.unitSystem,
            .kilograms
        )
    }

    // MARK: - Conversion

    func testConvertInventoryToKilogramsPreservesIdentifiersAndQuantities()
        throws {

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let plateID = UUID()
        let dumbbellID = UUID()

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        store.replace(
            with:
                EquipmentInventoryTestSupport
                    .makeInventory(
                        plates: [
                            PlateInventory(
                                id: plateID,
                                weight: 25,
                                quantity: 4
                            )
                        ],
                        dumbbells: [
                            DumbbellInventory(
                                id: dumbbellID,
                                weight: 20,
                                quantity: 2
                            )
                        ]
                    )
        )

        store.convertInventory(
            to: .kilograms
        )

        XCTAssertEqual(
            store.inventory.unitSystem,
            .kilograms
        )

        XCTAssertEqual(
            store.inventory.plates.first?.id,
            plateID
        )

        XCTAssertEqual(
            store.inventory.plates.first?.quantity,
            4
        )

        XCTAssertEqual(
            store.inventory.plates.first?.weight ?? 0,
            WeightConversion
                .poundsToKilograms(25),
            accuracy: 0.0001
        )

        XCTAssertEqual(
            store.inventory.dumbbells.first?.id,
            dumbbellID
        )

        XCTAssertEqual(
            store.inventory.dumbbells.first?.quantity,
            2
        )
    }

    func testConvertInventoryToSameUnitDoesNotRewriteValues() {
        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        let originalBarbell =
            store.inventory.barbellWeight

        let originalPlates =
            store.inventory.plates

        store.convertInventory(
            to: .pounds
        )

        XCTAssertEqual(
            store.inventory.barbellWeight,
            originalBarbell
        )

        XCTAssertEqual(
            store.inventory.plates,
            originalPlates
        )
    }

    // MARK: - Loading Increment

    func testSmallestPlateIncrementUsesSmallestPair() {
        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        store.replace(
            with:
                EquipmentInventoryTestSupport
                    .makeInventory(
                        plates: [
                            PlateInventory(
                                weight: 10,
                                quantity: 2
                            ),
                            PlateInventory(
                                weight: 2.5,
                                quantity: 2
                            ),
                            PlateInventory(
                                weight: 1.25,
                                quantity: 1
                            )
                        ],
                        dumbbells: []
                    )
        )

        XCTAssertEqual(
            store.smallestPlateIncrement(),
            5
        )
    }

    func testSmallestPlateIncrementConvertsKilogramInventoryToPounds() {
        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        store.replace(
            with:
                EquipmentInventoryTestSupport
                    .makeInventory(
                        unitSystem: .kilograms,
                        barbellWeight: 20,
                        plates: [
                            PlateInventory(
                                weight: 1.25,
                                quantity: 2
                            )
                        ],
                        dumbbells: []
                    )
        )

        XCTAssertEqual(
            store.smallestPlateIncrement(),
            6
        )
    }

    // MARK: - Error Clearing

    func testClearPersistenceErrorRemovesLoadingError() throws {
        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(
                    testName: #function
                )

        try Data("invalid".utf8).write(to: fileURL)

        let store = EquipmentInventoryStore(
            fileURL: fileURL
        )

        XCTAssertNotNil(
            store.persistenceError
        )

        store.clearPersistenceError()

        XCTAssertNil(
            store.persistenceError
        )
    }

    // MARK: - Migration from the legacy UserDefaults-backed store

    /// Regression test: a real inventory saved by the old
    /// `UserDefaults`-backed store, from before this persistence
    /// change, must still be picked up on the first launch after the
    /// change rather than silently resetting to defaults.
    func test_legacyUserDefaultsData_isMigratedOnFirstLoad() throws {
        let legacyDefaults =
            EquipmentInventoryTestSupport
                .makeUserDefaults(testName: #function)
        let legacyKey = "equipment_inventory_test"

        let legacyInventory =
            EquipmentInventoryTestSupport
                .makeInventory(barbellWeight: 35)

        legacyDefaults.set(
            try JSONEncoder().encode(legacyInventory),
            forKey: legacyKey
        )

        let fileURL =
            EquipmentInventoryTestSupport
                .makeFileURL(testName: #function)
        // No file exists yet at `fileURL` — this is the "first launch
        // since the persistence backend changed" case.
        let store = EquipmentInventoryStore(
            fileURL: fileURL,
            legacyUserDefaults: legacyDefaults,
            legacyPersistenceKey: legacyKey
        )

        XCTAssertNil(store.persistenceError)
        XCTAssertEqual(store.inventory.barbellWeight, 35)

        // The migration must have also written the file, so a
        // subsequent launch doesn't depend on the legacy UserDefaults
        // key still being present.
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
}
