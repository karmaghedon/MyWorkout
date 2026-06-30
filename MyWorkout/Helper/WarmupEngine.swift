import Foundation

struct WarmupEngine {
    static func generateWarmups(for workingWeight: Int, exerciseType: ExerciseType) -> [WarmupSet] {
        switch exerciseType {
        case .compound:
            return compoundWarmups(for: workingWeight)

        case .isolation:
            return isolationWarmups(for: workingWeight)

        case .bodyweight:
            return bodyweightWarmups()
        }
    }

    private static func compoundWarmups(for workingWeight: Int) -> [WarmupSet] {
        var warmups: [WarmupSet] = [
            WarmupSet(weight: 45, reps: 10),
            WarmupSet(weight: 45, reps: 8)
        ]

        if workingWeight >= 95 && workingWeight < 120 {
            warmups.append(WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.70), reps: 5))
        }

        if workingWeight >= 120 && workingWeight < 160 {
            warmups.append(WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.60), reps: 5))
            warmups.append(WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.80), reps: 3))
        }

        if workingWeight >= 160 && workingWeight < 210 {
            warmups.append(WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.50), reps: 5))
            warmups.append(WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.70), reps: 3))
            warmups.append(WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.85), reps: 2))
        }

        if workingWeight >= 210 {
            warmups.append(WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.50), reps: 5))
            warmups.append(WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.70), reps: 3))
            warmups.append(WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.85), reps: 2))
            warmups.append(WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.92), reps: 1))
        }

        return warmups.filter { $0.weight < workingWeight }
    }

    private static func isolationWarmups(for workingWeight: Int) -> [WarmupSet] {
        if workingWeight < 30 {
            return []
        }

        if workingWeight < 60 {
            return [
                WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.50), reps: 10)
            ].filter { $0.weight < workingWeight }
        }

        return [
            WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.50), reps: 10),
            WarmupSet(weight: roundToNearest5(Double(workingWeight) * 0.75), reps: 6)
        ].filter { $0.weight < workingWeight }
    }

    private static func bodyweightWarmups() -> [WarmupSet] {
        []
    }

    private static func roundToNearest5(_ value: Double) -> Int {
        Int((value / 5.0).rounded() * 5)
    }
}
