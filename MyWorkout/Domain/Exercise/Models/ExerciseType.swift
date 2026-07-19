import Foundation

enum ExerciseType:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case compound
    case isolation
    case bodyweight
}

extension ExerciseType {
    var displayName: String {
        switch self {
        case .compound:
            return "Compound"

        case .isolation:
            return "Isolation"

        case .bodyweight:
            return "Bodyweight"
        }
    }
}
