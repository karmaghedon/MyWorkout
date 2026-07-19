import Foundation

struct PlateCalculator {

    static func loading(
        for totalWeight: Double,
        inventory: EquipmentInventory
    ) -> PlateLoading {
        let barWeight = WeightConversion.toPounds(
            inventory.barbellWeight,
            from: inventory.unitSystem
        )

        let targetPerSide =
            (totalWeight - barWeight) / 2

        guard targetPerSide > 0 else {
            return PlateLoading(
                totalWeight: totalWeight,
                achievedWeight: barWeight,
                platesPerSide: []
            )
        }

        let availablePlates = inventory.plates
            .map {
                AvailablePlate(
                    weight: WeightConversion.toPounds(
                        $0.weight,
                        from: inventory.unitSystem
                    ),
                    quantityPerSide: max(
                        0,
                        $0.quantity / 2
                    )
                )
            }
            .filter {
                $0.weight > 0
                    && $0.quantityPerSide > 0
            }
            .sorted {
                $0.weight > $1.weight
            }

        let platesPerSide = optimalLoading(
            targetPerSide: targetPerSide,
            availablePlates: availablePlates
        )

        let loadedPerSide = platesPerSide.reduce(
            0,
            +
        )

        return PlateLoading(
            totalWeight: totalWeight,
            achievedWeight:
                barWeight + loadedPerSide * 2,
            platesPerSide: platesPerSide
        )
    }

    // MARK: - Optimal Loading

    private static func optimalLoading(
        targetPerSide: Double,
        availablePlates: [AvailablePlate]
    ) -> [Double] {
        guard !availablePlates.isEmpty else {
            return []
        }

        var best = LoadingCandidate.empty

        search(
            plateIndex: 0,
            currentWeight: 0,
            selectedPlates: [],
            targetPerSide: targetPerSide,
            availablePlates: availablePlates,
            best: &best
        )

        return best.plates
    }

    private static func search(
        plateIndex: Int,
        currentWeight: Double,
        selectedPlates: [Double],
        targetPerSide: Double,
        availablePlates: [AvailablePlate],
        best: inout LoadingCandidate
    ) {
        guard currentWeight <= targetPerSide + tolerance else {
            return
        }

        let candidate = LoadingCandidate(
            weight: currentWeight,
            plates: selectedPlates
        )

        if candidate.isBetter(
            than: best,
            targetPerSide: targetPerSide
        ) {
            best = candidate
        }

        guard plateIndex < availablePlates.count else {
            return
        }

        if abs(best.weight - targetPerSide) <= tolerance,
           selectedPlates.count >= best.plates.count {
            return
        }

        let plate = availablePlates[plateIndex]

        let maximumByWeight = Int(
            floor(
                (targetPerSide - currentWeight + tolerance)
                    / plate.weight
            )
        )

        let maximumCount = min(
            plate.quantityPerSide,
            max(0, maximumByWeight)
        )

        for count in stride(
            from: maximumCount,
            through: 0,
            by: -1
        ) {
            let addedWeight =
                Double(count) * plate.weight

            let nextSelectedPlates =
                selectedPlates
                + Array(
                    repeating: plate.weight,
                    count: count
                )

            search(
                plateIndex: plateIndex + 1,
                currentWeight:
                    currentWeight + addedWeight,
                selectedPlates: nextSelectedPlates,
                targetPerSide: targetPerSide,
                availablePlates: availablePlates,
                best: &best
            )
        }
    }

    // MARK: - Models

    private struct AvailablePlate {
        let weight: Double
        let quantityPerSide: Int
    }

    private struct LoadingCandidate {
        let weight: Double
        let plates: [Double]

        static let empty = LoadingCandidate(
            weight: 0,
            plates: []
        )

        func isBetter(
            than other: LoadingCandidate,
            targetPerSide: Double
        ) -> Bool {
            let residue =
                targetPerSide - weight

            let otherResidue =
                targetPerSide - other.weight

            if residue < otherResidue - tolerance {
                return true
            }

            guard abs(residue - otherResidue)
                    <= tolerance else {
                return false
            }

            if plates.count != other.plates.count {
                return plates.count < other.plates.count
            }

            return prefersHeavierPlates(
                over: other
            )
        }

        private func prefersHeavierPlates(
            over other: LoadingCandidate
        ) -> Bool {
            for (plate, otherPlate) in zip(
                plates,
                other.plates
            ) {
                if abs(plate - otherPlate)
                    <= tolerance {
                    continue
                }

                return plate > otherPlate
            }

            return false
        }
    }

    private static let tolerance = 0.001
}
