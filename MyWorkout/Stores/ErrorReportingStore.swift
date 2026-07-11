import Foundation

/// Common error-reporting boundary for persistent stores.
///
/// Legacy stores currently expose separate load/save errors.
/// ActiveWorkoutStore has migrated to the unified StoreError model.
/// Phase 7.2 will migrate the remaining stores.
protocol ErrorReportingStore: AnyObject {
    var currentError: String? { get }
}

// MARK: - Legacy Persistent Stores

extension WorkoutLogStore: ErrorReportingStore {
    var currentError: String? {
        persistenceError?.message
    }
}

extension WorkoutTemplateStore: ErrorReportingStore {
    var currentError: String? {
        persistenceError?.message
    }
}

extension EquipmentInventoryStore: ErrorReportingStore {
    var currentError: String? {
        lastSaveError ?? lastLoadError
    }
}

extension UserSettingsStore: ErrorReportingStore {
    var currentError: String? {
        lastSaveError ?? lastLoadError
    }
}

// MARK: - Unified Error Model

extension ActiveWorkoutStore: ErrorReportingStore {
    var currentError: String? {
        persistenceError?.message
    }
}
