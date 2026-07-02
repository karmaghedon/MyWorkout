import Foundation

struct WeightConversion {
    static func toPounds(_ value: Double, from unit: UnitSystem) -> Double {
        switch unit {
        case .pounds:
            return value
        case .kilograms:
            return value / 0.453592
        }
    }

    static func fromPounds(_ pounds: Double, to unit: UnitSystem) -> Double {
        switch unit {
        case .pounds:
            return pounds
        case .kilograms:
            return pounds * 0.453592
        }
    }
}
