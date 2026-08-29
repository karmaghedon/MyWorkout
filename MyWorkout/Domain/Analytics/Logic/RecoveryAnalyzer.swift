import Foundation

enum WarningSeverity: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct RecoveryWarning: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recommendation: String
    let severity: WarningSeverity
}

struct RecoveryAnalyzer {

    static func warnings(
        logs: [WorkoutLog],
        registry: ExerciseRegistry
    ) -> [RecoveryWarning] {
        var warnings: [RecoveryWarning] = []

        warnings.append(
            contentsOf: VolumeSpikeAnalyzer.warnings(
                logs: logs,
                registry: registry
            )
        )

        warnings.append(
            contentsOf: PerformanceDeclineAnalyzer.warnings(
                logs: logs
            )
        )

        warnings.append(
            contentsOf: IntraWorkoutFatigueAnalyzer.warnings(
                logs: logs
            )
        )

        return warnings
    }
}
