import Foundation

enum EquipmentInventoryConverter {
    static func converted(
        _ inventory: EquipmentInventory,
        to newUnit: UnitSystem
    ) -> EquipmentInventory {
        guard newUnit != inventory.unitSystem else {
            return inventory
        }

        var convertedInventory = inventory

        convertedInventory.barbellWeight = convert(
            inventory.barbellWeight,
            from: inventory.unitSystem,
            to: newUnit
        )

        convertedInventory.plates =
            inventory.plates.map { plate in
                PlateInventory(
                    id: plate.id,
                    weight: convert(
                        plate.weight,
                        from: inventory.unitSystem,
                        to: newUnit
                    ),
                    quantity: plate.quantity
                )
            }

        convertedInventory.dumbbells =
            inventory.dumbbells.map { dumbbell in
                DumbbellInventory(
                    id: dumbbell.id,
                    weight: convert(
                        dumbbell.weight,
                        from: inventory.unitSystem,
                        to: newUnit
                    ),
                    quantity: dumbbell.quantity
                )
            }

        convertedInventory.unitSystem = newUnit
        return convertedInventory
    }

    private static func convert(
        _ value: Double,
        from oldUnit: UnitSystem,
        to newUnit: UnitSystem
    ) -> Double {
        switch (oldUnit, newUnit) {
        case (.pounds, .kilograms):
            return WeightConversion.poundsToKilograms(
                value
            )

        case (.kilograms, .pounds):
            return WeightConversion.kilogramsToPounds(
                value
            )

        default:
            return value
        }
    }
}
