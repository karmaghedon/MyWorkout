import Foundation

final class EquipmentInventoryStore: ObservableObject {
    @Published var inventory: EquipmentInventory

    private let key = "equipment_inventory"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(EquipmentInventory.self, from: data) {
            inventory = decoded
        } else {
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

    private func sort() {
        inventory.plates.sort { $0.weight > $1.weight }
        inventory.dumbbells.sort { $0.weight < $1.weight }
    }
    
    func smallestPlateIncrement() -> Int {
        let smallestPlate = inventory.plates
            .filter { $0.quantity >= 2 }
            .map { $0.weight }
            .min() ?? 2.5

        return Int(smallestPlate * 2)
    }
}
