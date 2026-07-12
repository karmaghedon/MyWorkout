import Foundation

@MainActor
final class EquipmentInventoryStore: ObservableObject {
    @Published var inventory: EquipmentInventory

    @Published private(set) var persistenceError: StoreError?

    private let key = "equipment_inventory"

    init() {
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                inventory = try JSONDecoder().decode(
                    EquipmentInventory.self,
                    from: data
                )

                clearPersistenceError(for: .loading)
            } catch {
                print(
                    "Failed to load equipment inventory: \(error)"
                )

                UserDefaults.standard.removeObject(forKey: key)

                inventory = EquipmentInventory.defaultInventory

                setPersistenceError(
                    operation: .loading,
                    message:
                        "Couldn't load equipment inventory. "
                        + "Defaults were restored."
                )

                save()
            }
        } else {
            inventory = EquipmentInventory.defaultInventory
            save()
        }
    }

    // MARK: - Persistence Errors

    func clearPersistenceError() {
        persistenceError = nil
    }

    private func setPersistenceError(
        operation: StoreOperation,
        message: String
    ) {
        persistenceError = StoreError(
            operation: operation,
            message: message
        )
    }

    private func clearPersistenceError(
        for operation: StoreOperation
    ) {
        guard persistenceError?.operation == operation else {
            return
        }

        persistenceError = nil
    }

    // MARK: - Persistence

    func save() {
        do {
            let data = try JSONEncoder().encode(inventory)

            UserDefaults.standard.set(
                data,
                forKey: key
            )

            clearPersistenceError(for: .saving)
        } catch {
            print(
                "Failed to save equipment inventory: \(error)"
            )

            setPersistenceError(
                operation: .saving,
                message:
                    "Couldn't save equipment inventory."
            )
        }
    }

    // MARK: - Inventory Management

    func resetToDefault(unit: UnitSystem) {
        inventory = EquipmentInventory.defaultInventory

        if unit == .pounds {
            sort()
            save()
            return
        }

        convertInventory(to: unit)
    }

    func addPlate(
        weight: Double,
        quantity: Int
    ) {
        guard weight > 0, quantity > 0 else {
            return
        }

        inventory.plates.append(
            PlateInventory(
                weight: weight,
                quantity: quantity
            )
        )

        sort()
        save()
    }

    func addDumbbell(
        weight: Double,
        quantity: Int
    ) {
        guard weight > 0, quantity > 0 else {
            return
        }

        inventory.dumbbells.append(
            DumbbellInventory(
                weight: weight,
                quantity: quantity
            )
        )

        sort()
        save()
    }

    func deletePlates(at offsets: IndexSet) {
        inventory.plates.remove(atOffsets: offsets)
        save()
    }

    func deleteDumbbells(at offsets: IndexSet) {
        inventory.dumbbells.remove(atOffsets: offsets)
        save()
    }

    func deletePlate(id: UUID) {
        inventory.plates.removeAll {
            $0.id == id
        }

        save()
    }

    func deleteDumbbell(id: UUID) {
        inventory.dumbbells.removeAll {
            $0.id == id
        }

        save()
    }

    func replace(
        with newInventory: EquipmentInventory
    ) {
        inventory = newInventory
        sort()
        save()
    }

    // MARK: - Loading Increments

    func smallestPlateIncrement() -> Int {
        let smallestPlateInCurrentUnit = inventory.plates
            .filter { $0.quantity >= 2 }
            .map { $0.weight }
            .min() ?? 2.5

        let smallestPlateInPounds =
            WeightConversion.toPounds(
                smallestPlateInCurrentUnit,
                from: inventory.unitSystem
            )

        return max(
            1,
            Int(
                (smallestPlateInPounds * 2).rounded()
            )
        )
    }

    // MARK: - Unit Conversion

    func convertInventory(
        to newUnit: UnitSystem
    ) {
        let oldUnit = inventory.unitSystem

        guard newUnit != oldUnit else {
            return
        }

        func convert(_ value: Double) -> Double {
            switch (oldUnit, newUnit) {
            case (.pounds, .kilograms):
                return WeightConversion.poundsToKilograms(value)

            case (.kilograms, .pounds):
                return WeightConversion.kilogramsToPounds(value)

            default:
                return value
            }
        }

        inventory.barbellWeight = convert(
            inventory.barbellWeight
        )

        inventory.plates = inventory.plates.map {
            PlateInventory(
                id: $0.id,
                weight: convert($0.weight),
                quantity: $0.quantity
            )
        }

        inventory.dumbbells = inventory.dumbbells.map {
            DumbbellInventory(
                id: $0.id,
                weight: convert($0.weight),
                quantity: $0.quantity
            )
        }

        inventory.unitSystem = newUnit

        sort()
        save()
    }

    // MARK: - Helpers

    private func sort() {
        inventory.plates.sort {
            $0.weight > $1.weight
        }

        inventory.dumbbells.sort {
            $0.weight < $1.weight
        }
    }

//    private func roundToQuarter(
//        _ value: Double
//    ) -> Double {
//        Rounding.toNearestMultiple(
//            value,
//            of: 0.25
//        )
//    }
}
