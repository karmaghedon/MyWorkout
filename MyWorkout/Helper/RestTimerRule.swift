import Foundation

struct RestTimerRule {
    static func seconds(for exerciseType: ExerciseType) -> Int {
        switch exerciseType {
        case .compound:
            return 180
        case .isolation:
            return 90
        case .bodyweight:
            return 120
        }
    }
}
