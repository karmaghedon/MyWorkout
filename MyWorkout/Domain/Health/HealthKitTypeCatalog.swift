import HealthKit

/// The full set of HealthKit types this app ever reads or writes,
/// requested together in one authorization call
/// (`HealthKitAuthorizationManager.requestAuthorization()`) so the user
/// only ever sees one permission sheet, not one per feature phase.
/// Nutrition types are listed here starting from the very first
/// authorization request even though nothing writes to them until food
/// logging ships — asking again later would mean a second sheet.
enum HealthKitTypeCatalog {
    static let bodyMassType = HKQuantityType(.bodyMass)
    static let bodyFatPercentageType = HKQuantityType(.bodyFatPercentage)
    static let waistCircumferenceType = HKQuantityType(.waistCircumference)

    static let dietaryEnergyType = HKQuantityType(.dietaryEnergyConsumed)
    static let dietaryProteinType = HKQuantityType(.dietaryProtein)
    static let dietaryCarbohydratesType = HKQuantityType(.dietaryCarbohydrates)
    static let dietaryFatTotalType = HKQuantityType(.dietaryFatTotal)

    /// Read-only — this app never writes step counts, only reads what
    /// the phone/watch already recorded automatically.
    static let stepCountType = HKQuantityType(.stepCount)

    static let shareTypes: Set<HKSampleType> = [
        bodyMassType,
        bodyFatPercentageType,
        waistCircumferenceType,
        dietaryEnergyType,
        dietaryProteinType,
        dietaryCarbohydratesType,
        dietaryFatTotalType
    ]

    static let readTypes: Set<HKObjectType> = shareTypes.union([stepCountType])
}
