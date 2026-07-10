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

    func displayWeight(_ pounds: Double) -> Double {
        WeightConversion.displayWeight(fromStoredPounds: pounds, unitSystem: unitSystem)
    }

    func storageWeight(fromDisplayed value: Double) -> Double {
        WeightConversion.storedPounds(fromDisplayedWeight: value, unitSystem: unitSystem)
    }
}
