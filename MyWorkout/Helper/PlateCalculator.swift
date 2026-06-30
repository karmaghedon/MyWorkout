import Foundation

struct PlateCalculator {
    static func loading(for totalWeight: Int, inventory: EquipmentInventory) -> PlateLoading {
        let barWeight = inventory.barbellWeight
        let targetPerSide = (Double(totalWeight) - barWeight) / 2.0

        guard targetPerSide > 0 else {
            return PlateLoading(totalWeight: totalWeight, platesPerSide: [])
        }

        let platesPerSideInventory = inventory.plates
            .map { PlateInventory(weight: $0.weight, quantity: $0.quantity / 2) }
            .filter { $0.quantity > 0 }
            .sorted { $0.weight > $1.weight }

        var remaining = targetPerSide
        var result: [Double] = []

        for plate in platesPerSideInventory {
            var used = 0

            while remaining >= plate.weight && used < plate.quantity {
                result.append(plate.weight)
                remaining -= plate.weight
                used += 1
            }
        }

        return PlateLoading(totalWeight: totalWeight, platesPerSide: result)
    }
}
