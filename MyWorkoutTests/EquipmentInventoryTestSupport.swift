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
        from userDefaults: UserDefaults,
        key: String
    ) throws -> EquipmentInventory {
        let data = try XCTUnwrap(
            userDefaults.data(
                forKey: key
            )
        )

        return try JSONDecoder().decode(
            EquipmentInventory.self,
            from: data
        )
    }
}
