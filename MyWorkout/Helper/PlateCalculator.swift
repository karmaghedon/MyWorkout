import Foundation

struct PlateCalculator {
    static func loading(for totalWeight: Int, inventory: EquipmentInventory) -> PlateLoading {
        let barWeightLb = WeightConversion.toPounds(
            inventory.barbellWeight,
            from: inventory.unitSystem
        )

        let targetPerSide = (Double(totalWeight) - barWeightLb) / 2.0

        guard targetPerSide > 0 else {
            return PlateLoading(totalWeight: totalWeight, platesPerSide: [])
        }

        let platesPerSideInventory = inventory.plates
            .map {
                PlateInventory(
                    id: $0.id,
                    weight: WeightConversion.toPounds($0.weight, from: inventory.unitSystem),
                    quantity: $0.quantity / 2
                )
            }
            .filter { $0.quantity > 0 }
            .sorted { $0.weight > $1.weight }

        var remaining = targetPerSide
        var result: [Double] = []

        for plate in platesPerSideInventory {
            var used = 0

            while remaining + 0.001 >= plate.weight && used < plate.quantity {
                result.append(plate.weight)
                remaining -= plate.weight
                used += 1
            }
        }

        return PlateLoading(totalWeight: totalWeight, platesPerSide: result)
    }
}
