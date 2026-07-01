import Foundation

struct EquipmentInventory: Codable {
    var barbellWeight: Double
    var plates: [PlateInventory]
    var dumbbells: [DumbbellInventory]

    static let defaultInventory = EquipmentInventory(
        barbellWeight: 45,
        plates: [
            PlateInventory(weight: 45, quantity: 2),
            PlateInventory(weight: 35, quantity: 2),
            PlateInventory(weight: 25, quantity: 4),
            PlateInventory(weight: 10, quantity: 2),
            PlateInventory(weight: 5, quantity: 4),
            PlateInventory(weight: 2.5, quantity: 2)
        ],
        dumbbells: [
            DumbbellInventory(weight: 5, quantity: 2),
            DumbbellInventory(weight: 10, quantity: 2),
            DumbbellInventory(weight: 15, quantity: 2),
            DumbbellInventory(weight: 20, quantity: 2),
            DumbbellInventory(weight: 25, quantity: 2),
            DumbbellInventory(weight: 30, quantity: 2),
            DumbbellInventory(weight: 35, quantity: 2),
            DumbbellInventory(weight: 40, quantity: 2),
            DumbbellInventory(weight: 45, quantity: 2),
            DumbbellInventory(weight: 50, quantity: 2)
        ]
    )
}

struct PlateInventory: Identifiable, Codable, Equatable {
    var id = UUID()
    var weight: Double
    var quantity: Int
}

struct DumbbellInventory: Identifiable, Codable, Equatable {
    var id = UUID()
    var weight: Double
    var quantity: Int
}
