import Foundation

struct AnalyticsSnapshot {
    let totalSets: Int
    let volumeByMuscleGroup: [MuscleGroupVolume]
    let personalRecords: [PersonalRecord]
    let recoveryWarnings: [RecoveryWarning]
    let performanceWarnings: [ExercisePerformanceWarning]

    static let empty = AnalyticsSnapshot(
        totalSets: 0,
        volumeByMuscleGroup: [],
        personalRecords: [],
        recoveryWarnings: [],
        performanceWarnings: []
    )
}
