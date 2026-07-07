import Foundation

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case pounds = "lb"
    case kilograms = "kg"

    var id: String { rawValue }
}

enum OneRepMaxFormula: String, Codable, CaseIterable, Identifiable {
    case epley = "Epley"
    case brzycki = "Brzycki"

    var id: String { rawValue }
}

struct UserSettings: Codable {
    var unitSystem: UnitSystem
    var compoundRestSeconds: Int
    var isolationRestSeconds: Int
    var bodyweightRestSeconds: Int
    var oneRepMaxFormula: OneRepMaxFormula
    var compoundIncrement: Int
    var isolationIncrement: Int

    static let defaults = UserSettings(
        unitSystem: .pounds,
        compoundRestSeconds: 180,
        isolationRestSeconds: 90,
        bodyweightRestSeconds: 120,
        oneRepMaxFormula: .epley,
        compoundIncrement: 5,
        isolationIncrement: 5
    )

    var weightUnitLabel: String {
        unitSystem.rawValue
    }

    /// Stored value is always pounds.
    func displayWeight(_ pounds: Double) -> Double {
        switch unitSystem {
        case .pounds:
            return pounds.rounded()
        case .kilograms:
            return (pounds * 0.453592 * 10).rounded() / 10
        }
    }

    /// Converts displayed user input back to stored pounds.
    func storageWeight(fromDisplayed value: Double) -> Double {
        switch unitSystem {
        case .pounds:
            return value
        case .kilograms:
            return value / 0.453592
        }
    }
}
