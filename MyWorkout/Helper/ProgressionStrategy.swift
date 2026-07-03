import Foundation

enum ProgressionStrategy: String, Codable, CaseIterable, Identifiable {
    case doubleProgression
    case slowProgression
    case repsThenWeight
    case bodyweightReps

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .doubleProgression:
            return "Double Progression"
        case .slowProgression:
            return "Slow Progression"
        case .repsThenWeight:
            return "Reps Then Weight"
        case .bodyweightReps:
            return "Bodyweight Reps"
        }
    }
}
