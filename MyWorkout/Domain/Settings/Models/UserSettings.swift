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

/// The app's display appearance. Kept free of SwiftUI (no `ColorScheme`)
/// so this Domain model has no UI-framework dependency; the View layer
/// maps this to `ColorScheme` where it applies `.preferredColorScheme`.
enum AppearanceMode:
    String,
    Codable,
    CaseIterable,
    Identifiable {

    case system
    case light
    case dark

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .system:
            "Auto"
        case .light:
            "Day"
        case .dark:
            "Night"
        }
    }
}

/// Which layout `WorkoutSessionView` renders: the original stepper-based
/// card (`classic`) or the newer warm-up/working-set checklist
/// (`checklist`). Foundation-only, same reasoning as `AppearanceMode`.
enum WorkoutSessionLayout:
    String,
    Codable,
    CaseIterable,
    Identifiable {

    case classic
    case checklist

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .classic:
            "Classic"
        case .checklist:
            "Checklist"
        }
    }
}

struct UserSettings: Codable {
    var unitSystem: UnitSystem
    /// Separate from `unitSystem`, which governs training weights
    /// (barbell/plates/dumbbells, workout logging). Body-metrics screens
    /// (`LogWeightView`, `WeeklyReportView`) use this instead, so the two
    /// can be switched independently — e.g. training in lb while tracking
    /// body weight in kg.
    var bodyWeightUnitSystem: UnitSystem
    /// Only used to pick which U.S. Navy body-fat formula variant
    /// applies (`NavyBodyFatCalculator`). `nil` until the user fills in
    /// the Body Profile section — the calculator simply can't produce
    /// an estimate until then.
    var biologicalSex: BiologicalSex?
    /// Centimeters. Same reasoning as `biologicalSex`: `nil` until set,
    /// needed only for the Navy body-fat estimate.
    var heightCm: Double?
    var compoundRestSeconds: Int
    var isolationRestSeconds: Int
    var bodyweightRestSeconds: Int
    var oneRepMaxFormula: OneRepMaxFormula
    var compoundIncrement: Int
    var isolationIncrement: Int
    var appearanceMode: AppearanceMode
    var workoutSessionLayout: WorkoutSessionLayout

    static let defaults = UserSettings(
        unitSystem: .pounds,
        bodyWeightUnitSystem: .pounds,
        biologicalSex: nil,
        heightCm: nil,
        compoundRestSeconds: 180,
        isolationRestSeconds: 90,
        bodyweightRestSeconds: 120,
        oneRepMaxFormula: .epley,
        compoundIncrement: 5,
        isolationIncrement: 5,
        appearanceMode: .system,
        workoutSessionLayout: .classic
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
        case bodyWeightUnitSystem
        case biologicalSex
        case heightCm
        case compoundRestSeconds
        case isolationRestSeconds
        case bodyweightRestSeconds
        case oneRepMaxFormula
        case compoundIncrement
        case isolationIncrement
        case appearanceMode
        case workoutSessionLayout
    }

    init(
        unitSystem: UnitSystem,
        bodyWeightUnitSystem: UnitSystem,
        biologicalSex: BiologicalSex?,
        heightCm: Double?,
        compoundRestSeconds: Int,
        isolationRestSeconds: Int,
        bodyweightRestSeconds: Int,
        oneRepMaxFormula: OneRepMaxFormula,
        compoundIncrement: Int,
        isolationIncrement: Int,
        appearanceMode: AppearanceMode,
        workoutSessionLayout: WorkoutSessionLayout
    ) {
        self.unitSystem = unitSystem
        self.bodyWeightUnitSystem = bodyWeightUnitSystem
        self.biologicalSex = biologicalSex
        self.heightCm = heightCm
        self.compoundRestSeconds = compoundRestSeconds
        self.isolationRestSeconds = isolationRestSeconds
        self.bodyweightRestSeconds = bodyweightRestSeconds
        self.oneRepMaxFormula = oneRepMaxFormula
        self.compoundIncrement = compoundIncrement
        self.isolationIncrement = isolationIncrement
        self.appearanceMode = appearanceMode
        self.workoutSessionLayout = workoutSessionLayout
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

        bodyWeightUnitSystem = try container.decodeIfPresent(
            UnitSystem.self,
            forKey: .bodyWeightUnitSystem
        ) ?? defaults.bodyWeightUnitSystem

        biologicalSex = try container.decodeIfPresent(
            BiologicalSex.self,
            forKey: .biologicalSex
        ) ?? defaults.biologicalSex

        heightCm = try container.decodeIfPresent(
            Double.self,
            forKey: .heightCm
        ) ?? defaults.heightCm

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

        appearanceMode = try container.decodeIfPresent(
            AppearanceMode.self,
            forKey: .appearanceMode
        ) ?? defaults.appearanceMode

        workoutSessionLayout = try container.decodeIfPresent(
            WorkoutSessionLayout.self,
            forKey: .workoutSessionLayout
        ) ?? defaults.workoutSessionLayout
    }
}
