import Foundation

@MainActor
protocol EquipmentReplacing {
    func replace(
        with newInventory: EquipmentInventory
    )
}

extension EquipmentInventoryStore:
    EquipmentReplacing {}
