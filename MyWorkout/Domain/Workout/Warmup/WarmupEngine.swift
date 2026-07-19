import Foundation

struct WarmupEngine {
    static func generateWarmups(
        for workingWeight: Double,
        exerciseType: ExerciseType,
        usesBarbell: Bool = true,
        barbellWeight: Double = 45
    ) -> [WarmupSet] {
        switch exerciseType {
        case .compound:
            if usesBarbell {
                return barbellCompoundWarmups(for: workingWeight, barbellWeight: barbellWeight)
            } else {
                return dumbellCompoundWarmups(for: workingWeight)
            }

        case .isolation:
            return isolationWarmups(for: workingWeight)

        case .bodyweight:
            return bodyweightWarmups()
        }
    }

    private static func barbellCompoundWarmups(for workingWeight: Double, barbellWeight: Double) -> [WarmupSet] {
        var warmups: [WarmupSet] = [
            WarmupSet(weight: barbellWeight, reps: 10),
            WarmupSet(weight: barbellWeight, reps: 8)
        ]
        
        if workingWeight >= 95 && workingWeight < 120 {
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.70), reps: 5))
        }
        
        if workingWeight >= 120 && workingWeight < 160 {
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.60), reps: 5))
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.80), reps: 3))
        }
        
        if workingWeight >= 160 && workingWeight < 210 {
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.50), reps: 5))
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.70), reps: 3))
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.85), reps: 2))
        }
        
        if workingWeight >= 210 {
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.50), reps: 5))
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.70), reps: 3))
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.85), reps: 2))
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.92), reps: 1))
        }
        return warmups.filter { $0.weight < workingWeight && $0.weight >= barbellWeight}
    }
    
    private static func dumbellCompoundWarmups(for workingWeight: Double) -> [WarmupSet] {
        if workingWeight < 30 {
            return []
        }
        
        var warmups: [WarmupSet] = [
            WarmupSet(weight: roundToNearest5(workingWeight * 0.40), reps: 10)
        ]
        
        if workingWeight >= 50 {
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.60), reps: 6))
        }
        
        if workingWeight >= 80 {
            warmups.append(WarmupSet(weight: roundToNearest5(workingWeight * 0.75), reps: 4))
        }

        return warmups.filter { $0.weight < workingWeight }
    }

    private static func isolationWarmups(for workingWeight: Double) -> [WarmupSet] {
        if workingWeight < 30 {
            return []
        }

        if workingWeight < 60 {
            return [
                WarmupSet(weight: roundToNearest5(workingWeight * 0.50), reps: 10)
            ].filter { $0.weight < workingWeight }
        }

        return [
            WarmupSet(weight: roundToNearest5(workingWeight * 0.50), reps: 10),
            WarmupSet(weight: roundToNearest5(workingWeight * 0.75), reps: 6)
        ].filter { $0.weight < workingWeight }
    }

    private static func bodyweightWarmups() -> [WarmupSet] {
        []
    }

    private static func roundToNearest5(_ value: Double) -> Double {
        Rounding.toNearestMultiple(value, of: 5)
    }
}
