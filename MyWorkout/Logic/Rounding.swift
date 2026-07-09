import Foundation

/// Small shared rounding helpers so "round to nearest 5", "round to nearest
/// quarter", and "round to N decimal places" aren't each reimplemented
/// privately wherever they're needed.
enum Rounding {
    /// Rounds to the nearest multiple of `increment` (e.g. nearest 5, nearest 0.25).
    static func toNearestMultiple(_ value: Double, of increment: Double) -> Double {
        guard increment > 0 else { return value }
        return (value / increment).rounded() * increment
    }

    /// Rounds to a fixed number of decimal places (e.g. nearest 0.1).
    static func toDecimalPlaces(_ value: Double, _ places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (value * multiplier).rounded() / multiplier
    }
}
