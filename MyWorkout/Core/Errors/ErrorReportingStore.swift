import Foundation

/// Shared error-reporting boundary for persistent stores.
///
/// Every persistent store exposes the same StoreError model.
/// DashboardView can aggregate errors without knowing each store's
/// implementation details.
protocol ErrorReportingStore: AnyObject {
    var persistenceError: StoreError? { get }
}

extension ErrorReportingStore {
    var currentError: String? {
        persistenceError?.message
    }
}

// MARK: - Store Conformance

extension WorkoutLogStore: ErrorReportingStore {}

extension WorkoutTemplateStore: ErrorReportingStore {}

extension EquipmentInventoryStore: ErrorReportingStore {}

extension UserSettingsStore: ErrorReportingStore {}

extension ActiveWorkoutStore: ErrorReportingStore {}

extension CustomExerciseStore: ErrorReportingStore {}

extension BodyMeasurementLogStore: ErrorReportingStore {}
