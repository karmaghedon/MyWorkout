import Foundation

enum UnitSystem:
    String,
    Codable,
    CaseIterable,
    Identifiable {

    case pounds = "lb"
    case kilograms = "kg"

    var id: String {
        rawValue
    }
}

enum OneRepMaxFormula:
    String,
    Codable,
    CaseIterable,
    Identifiable {

    case epley = "Epley"
    case brzycki = "Brzycki"

    var id: String {
        rawValue
    }
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

    func displayWeight(
        _ pounds: Double
    ) -> Double {
        WeightConversion.displayWeight(
            fromStoredPounds: pounds,
            unitSystem: unitSystem
        )
    }

    func storageWeight(
        fromDisplayed value: Double
    ) -> Double {
        WeightConversion.storedPounds(
            fromDisplayedWeight: value,
            unitSystem: unitSystem
        )
    }

    // MARK: - Backward-Compatible Decoding

    private enum CodingKeys: String, CodingKey {
        case unitSystem
        case compoundRestSeconds
        case isolationRestSeconds
        case bodyweightRestSeconds
        case oneRepMaxFormula
        case compoundIncrement
        case isolationIncrement
    }

    init(
        unitSystem: UnitSystem,
        compoundRestSeconds: Int,
        isolationRestSeconds: Int,
        bodyweightRestSeconds: Int,
        oneRepMaxFormula: OneRepMaxFormula,
        compoundIncrement: Int,
        isolationIncrement: Int
    ) {
        self.unitSystem = unitSystem
        self.compoundRestSeconds = compoundRestSeconds
        self.isolationRestSeconds = isolationRestSeconds
        self.bodyweightRestSeconds = bodyweightRestSeconds
        self.oneRepMaxFormula = oneRepMaxFormula
        self.compoundIncrement = compoundIncrement
        self.isolationIncrement = isolationIncrement
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        let defaults = Self.defaults

        unitSystem = try container.decodeIfPresent(
            UnitSystem.self,
            forKey: .unitSystem
        ) ?? defaults.unitSystem

        compoundRestSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .compoundRestSeconds
        ) ?? defaults.compoundRestSeconds

        isolationRestSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .isolationRestSeconds
        ) ?? defaults.isolationRestSeconds

        bodyweightRestSeconds = try container.decodeIfPresent(
            Int.self,
            forKey: .bodyweightRestSeconds
        ) ?? defaults.bodyweightRestSeconds

        oneRepMaxFormula = try container.decodeIfPresent(
            OneRepMaxFormula.self,
            forKey: .oneRepMaxFormula
        ) ?? defaults.oneRepMaxFormula

        compoundIncrement = try container.decodeIfPresent(
            Int.self,
            forKey: .compoundIncrement
        ) ?? defaults.compoundIncrement

        isolationIncrement = try container.decodeIfPresent(
            Int.self,
            forKey: .isolationIncrement
        ) ?? defaults.isolationIncrement
    }
}
