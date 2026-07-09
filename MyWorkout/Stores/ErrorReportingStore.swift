import Foundation

/// Conformed to by every store that persists data and surfaces failures to
/// the UI, so callers (like DashboardView's error banners) can handle all of
/// them generically instead of repeating the same `lastSaveError ??
/// lastLoadError` check once per store.
protocol ErrorReportingStore: AnyObject {
    var lastSaveError: String? { get }
    var lastLoadError: String? { get }
}

extension ErrorReportingStore {
    /// The most relevant error to show right now, if any.
    var currentError: String? {
        lastSaveError ?? lastLoadError
    }
}

extension WorkoutLogStore: ErrorReportingStore {}
extension WorkoutTemplateStore: ErrorReportingStore {}
extension EquipmentInventoryStore: ErrorReportingStore {}
extension UserSettingsStore: ErrorReportingStore {}
extension ActiveWorkoutStore: ErrorReportingStore {}
