import Foundation
import XCTest
@testable import MyWorkout

enum EquipmentInventoryTestSupport {

    static func makeUserDefaults(
        testName: String
    ) -> UserDefaults {
        let suiteName =
            "EquipmentInventoryStoreTests."
            + testName
            + "."
            + UUID().uuidString

        let defaults = UserDefaults(
            suiteName: suiteName
        )!

        defaults.removePersistentDomain(
            forName: suiteName
        )

        return defaults
    }

    /// A unique file path per test/call, so tests never see each
    /// other's data despite running against the real filesystem — same
    /// isolation goal `makeUserDefaults` served before
    /// `EquipmentInventoryStore` moved off `UserDefaults` (whose
    /// `synchronize()` turned out not to reliably flush before process
    /// termination — see the type-level doc comment on
    /// `UserSettingsStore`, which hit the identical issue).
    /// `makeUserDefaults` above is kept only for
    /// `test_legacyUserDefaultsData_isMigratedOnFirstLoad`, which
    /// specifically needs a real `UserDefaults` to migrate from.
    static func makeFileURL(
        testName: String
    ) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "EquipmentInventoryStoreTests."
                + testName
                + "."
                + UUID().uuidString
                + ".json"
            )
    }

    static func makeInventory(
        unitSystem: UnitSystem = .pounds,
        barbellWeight: Double = 45,
        plates: [PlateInventory] = [
            PlateInventory(
                weight: 25,
                quantity: 2
            ),
            PlateInventory(
                weight: 5,
                quantity: 4
            )
        ],
        dumbbells: [DumbbellInventory] = [
            DumbbellInventory(
                weight: 20,
                quantity: 2
            ),
            DumbbellInventory(
                weight: 10,
                quantity: 2
            )
        ]
    ) -> EquipmentInventory {
        EquipmentInventory(
            unitSystem: unitSystem,
            barbellWeight: barbellWeight,
            plates: plates,
            dumbbells: dumbbells
        )
    }

    static func decodeInventory(
        from fileURL: URL
    ) throws -> EquipmentInventory {
        let data = try Data(contentsOf: fileURL)

        return try JSONDecoder().decode(
            EquipmentInventory.self,
            from: data
        )
    }
}
