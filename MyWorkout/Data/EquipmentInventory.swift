import Foundation

struct EquipmentInventory: Codable {
    var unitSystem: UnitSystem
    var barbellWeight: Double
    var plates: [PlateInventory]
    var dumbbells: [DumbbellInventory]

    static let defaultInventory = EquipmentInventory(
        unitSystem: .pounds,
        barbellWeight: 45,
        plates: [
            PlateInventory(weight: 45, quantity: 2),
            PlateInventory(weight: 35, quantity: 2),
            PlateInventory(weight: 25, quantity: 4),
            PlateInventory(weight: 10, quantity: 2),
            PlateInventory(weight: 5, quantity: 4),
            PlateInventory(weight: 2.5, quantity: 2)
        ],
        dumbbells: []
    )
}

struct PlateInventory: Identifiable, Codable, Equatable {
    var id: UUID
    var weight: Double
    var quantity: Int

    init(id: UUID = UUID(), weight: Double, quantity: Int) {
        self.id = id
        self.weight = weight
        self.quantity = quantity
    }
}

struct DumbbellInventory: Identifiable, Codable, Equatable {
    var id: UUID
    var weight: Double
    var quantity: Int

    init(id: UUID = UUID(), weight: Double, quantity: Int) {
        self.id = id
        self.weight = weight
        self.quantity = quantity
    }
}


