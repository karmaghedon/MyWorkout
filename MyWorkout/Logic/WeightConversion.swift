import Foundation

/// Centralized weight conversion for the entire application.
///
/// Architectural rule:
/// - Workout, history, progression, and analytics weights are stored in pounds.
/// - Conversion to kilograms happens only at display and input boundaries.
enum WeightConversion {

    // MARK: - Constants

    static let poundsPerKilogram = 2.2046226218
    static let kilogramsPerPound = 0.45359237

    // MARK: - Base Conversion

    static func kilogramsToPounds(_ kilograms: Double) -> Double {
        kilograms * poundsPerKilogram
    }

    static func poundsToKilograms(_ pounds: Double) -> Double {
        pounds * kilogramsPerPound
    }

    // MARK: - Compatibility Conversion

    /// Converts a value expressed in the selected unit into pounds.
    ///
    /// Retained temporarily while older consumers are migrated.
    static func toPounds(
        _ value: Double,
        from unitSystem: UnitSystem
    ) -> Double {
        switch unitSystem {
        case .pounds:
            return value

        case .kilograms:
            return kilogramsToPounds(value)
        }
    }

    /// Converts pounds into the selected unit.
    ///
    /// Retained temporarily while older consumers are migrated.
    static func fromPounds(
        _ pounds: Double,
        to unitSystem: UnitSystem
    ) -> Double {
        switch unitSystem {
        case .pounds:
            return pounds

        case .kilograms:
            return poundsToKilograms(pounds)
        }
    }

    // MARK: - Workout Storage Boundary

    /// Converts canonical stored pounds into the selected display unit.
    static func displayWeight(
        fromStoredPounds pounds: Double,
        unitSystem: UnitSystem
    ) -> Double {
        switch unitSystem {
        case .pounds:
            return pounds

        case .kilograms:
            return roundToDecimalPlaces(
                poundsToKilograms(pounds),
                places: 1
            )
        }
    }

    /// Converts displayed input into canonical stored pounds.
    ///
    /// Stored values are normalized to quarter-pound precision to prevent
    /// lb/kg round-trip drift while still supporting fractional loads.
    static func storedPounds(
        fromDisplayedWeight value: Double,
        unitSystem: UnitSystem
    ) -> Double {
        let pounds = toPounds(value, from: unitSystem)

        return roundToNearest(pounds, step: 0.25)
    }

    /// Converts a canonical pound increment into a practical display increment.
    static func displayStep(
        fromStoredPounds step: Double,
        unitSystem: UnitSystem
    ) -> Double {
        switch unitSystem {
        case .pounds:
            return step

        case .kilograms:
            let kilograms = poundsToKilograms(step)

            return max(
                0.5,
                roundToNearest(kilograms, step: 0.5)
            )
        }
    }

    // MARK: - Rounding

    static func roundToDecimalPlaces(
        _ value: Double,
        places: Int
    ) -> Double {
        let factor = pow(10.0, Double(places))
        return (value * factor).rounded() / factor
    }

    static func roundToNearest(
        _ value: Double,
        step: Double
    ) -> Double {
        guard step > 0 else {
            return value
        }

        return (value / step).rounded() * step
    }
}
