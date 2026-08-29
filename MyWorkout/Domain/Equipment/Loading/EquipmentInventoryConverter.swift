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

    /// Standard Olympic barbell/plate weights that are sold and marketed
    /// as interchangeable lb⟷kg pairs, even though they aren't precisely
    /// mathematically equal — a "45 lb" bar or plate is the conventional
    /// counterpart to a "20 kg" one industry-wide (45 lb is precisely
    /// 20.41 kg, not 20 kg). Converting these by formula instead of by
    /// convention is what produced the original bug report: a mathematically
    /// "correct" 45 lb → 20.41 kg isn't what any gym-goer means by
    /// "the 20 kg bar." Pairs sourced from standard Olympic plate/barbell
    /// conventions (2.5/5/10/25/35/45 lb ⟷ 1.25/2.5/5/10/15/20 kg).
    private static let standardPoundsToKilograms: [Double: Double] = [
        2.5: 1.25,
        5: 2.5,
        10: 5,
        25: 10,
        35: 15,
        45: 20
    ]

    private static let standardKilogramsToPounds: [Double: Double] = Dictionary(
        uniqueKeysWithValues: standardPoundsToKilograms.map { ($1, $0) }
    )

    /// Converts, preferring an exact standard-pair match over formula
    /// conversion so round-tripping a standard weight (45 lb → 20 kg →
    /// 45 lb) stays exact rather than drifting through rounded math each
    /// way. Only weights outside the standard table fall back to
    /// `WeightConversion`'s formula, rounded to a sensible precision for
    /// the target unit.
    private static func convert(
        _ value: Double,
        from oldUnit: UnitSystem,
        to newUnit: UnitSystem
    ) -> Double {
        switch (oldUnit, newUnit) {
        case (.pounds, .kilograms):
            if let standard = standardPoundsToKilograms[value] {
                return standard
            }

            return WeightConversion.roundToNearest(
                WeightConversion.poundsToKilograms(value),
                step: 0.5
            )

        case (.kilograms, .pounds):
            if let standard = standardKilogramsToPounds[value] {
                return standard
            }

            return WeightConversion.roundToNearest(
                WeightConversion.kilogramsToPounds(value),
                step: 0.25
            )

        default:
            return value
        }
    }
}
