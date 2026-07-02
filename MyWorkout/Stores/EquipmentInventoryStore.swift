import Foundation

final class EquipmentInventoryStore: ObservableObject {
    @Published var inventory: EquipmentInventory

    private let key = "equipment_inventory"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(EquipmentInventory.self, from: data) {
            inventory = decoded
        } else {
            UserDefaults.standard.removeObject(forKey: key)
            inventory = EquipmentInventory.defaultInventory
            save()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(inventory)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save equipment inventory: \(error)")
        }
    }

    func resetToDefault(unit: UnitSystem) {
        inventory = EquipmentInventory.defaultInventory
        convertInventory(to: unit, from: .pounds)
        save()
    }

    func addPlate(weight: Double, quantity: Int) {
        inventory.plates.append(PlateInventory(weight: weight, quantity: quantity))
        sort()
        save()
    }

    func addDumbbell(weight: Double, quantity: Int) {
        inventory.dumbbells.append(DumbbellInventory(weight: weight, quantity: quantity))
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
    
    func replace(with newInventory: EquipmentInventory) {
        inventory = newInventory
        save()
    }

    private func sort() {
        inventory.plates.sort { $0.weight > $1.weight }
        inventory.dumbbells.sort { $0.weight < $1.weight }
    }

    func smallestPlateIncrement() -> Int {
        let smallestPlateInCurrentUnit = inventory.plates
            .filter { $0.quantity >= 2 }
            .map { $0.weight }
            .min() ?? 2.5

        let smallestPlateInPounds = WeightConversion.toPounds(
            smallestPlateInCurrentUnit,
            from: inventory.unitSystem
        )

        return max(1, Int((smallestPlateInPounds * 2).rounded()))
    }

    func convertInventory(to newUnit: UnitSystem, from oldUnit: UnitSystem) {
        guard newUnit != oldUnit else { return }

        func convert(_ value: Double) -> Double {
            switch (oldUnit, newUnit) {
            case (.pounds, .kilograms):
                return roundToHalf(value * 0.453592)
            case (.kilograms, .pounds):
                return roundToHalf(value / 0.453592)
            default:
                return value
            }
        }

        inventory.barbellWeight = convert(inventory.barbellWeight)

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

    private func roundToHalf(_ value: Double) -> Double {
        (value * 2).rounded() / 2
    }
}
