import Foundation

struct RestTimerRule {
    static func seconds(for exerciseType: ExerciseType, settings: UserSettings) -> Int {
        switch exerciseType {
        case .compound:
            return settings.compoundRestSeconds
        case .isolation:
            return settings.isolationRestSeconds
        case .bodyweight:
            return settings.bodyweightRestSeconds
        }
    }
}
