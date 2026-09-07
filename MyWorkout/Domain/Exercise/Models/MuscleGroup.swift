import Foundation

/// Broad muscle-group category used for exercise organization,
/// filtering, volume summaries, and workout planning.
///
/// Detailed anatomical muscles remain represented separately by
/// `primaryMuscles` and `secondaryMuscles`.
enum MuscleGroup: Hashable, Identifiable, Comparable, Codable {
    case chest
    case back
    case shoulders
    case quadriceps
    case hamstrings
    case glutes
    case legs
    case biceps
    case triceps
    case arms
    case calves
    case core
    case fullBody
    case other(String)

    var id: String {
        storageValue
    }

    var displayName: String {
        switch self {
        case .chest:
            return "Chest"

        case .back:
            return "Back"

        case .shoulders:
            return "Shoulders"

        case .quadriceps:
            return "Quadriceps"

        case .hamstrings:
            return "Hamstrings"

        case .glutes:
            return "Glutes"

        case .legs:
            return "Legs"

        case .biceps:
            return "Biceps"

        case .triceps:
            return "Triceps"

        case .arms:
            return "Arms"

        case .calves:
            return "Calves"

        case .core:
            return "Core"

        case .fullBody:
            return "Full Body"

        case .other(let value):
            return value
        }
    }

    var systemImage: String {
        switch self {
        case .chest:
            return "figure.strengthtraining.traditional"

        case .back:
            return "figure.rower"

        case .shoulders:
            return "figure.strengthtraining.functional"

        case .quadriceps,
             .hamstrings,
             .glutes,
             .legs,
             .calves:
            return "figure.run"

        case .biceps,
             .triceps,
             .arms:
            return "dumbbell.fill"

        case .core:
            return "figure.core.training"

        case .fullBody:
            return "figure.cross.training"

        case .other:
            return "figure.strengthtraining.traditional"
        }
    }

    static func < (
        lhs: MuscleGroup,
        rhs: MuscleGroup
    ) -> Bool {
        lhs.displayName.localizedCaseInsensitiveCompare(
            rhs.displayName
        ) == .orderedAscending
    }

    // MARK: - Legacy Compatibility

    init(legacyValue: String) {
        let trimmed = legacyValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        switch trimmed.lowercased() {
        case "chest":
            self = .chest

        case "back":
            self = .back

        case "shoulder", "shoulders":
            self = .shoulders

        case "quad", "quads", "quadriceps":
            self = .quadriceps

        case "hamstring", "hamstrings":
            self = .hamstrings

        case "glute", "glutes":
            self = .glutes

        case "leg", "legs", "lower body":
            self = .legs

        case "bicep", "biceps":
            self = .biceps

        case "tricep", "triceps":
            self = .triceps

        case "arm", "arms":
            self = .arms

        case "calf", "calves":
            self = .calves

        case "abs", "abdominals", "core":
            self = .core

        case "full body", "full-body":
            self = .fullBody

        default:
            self = .other(
                trimmed.isEmpty ? "Other" : trimmed
            )
        }
    }

    // MARK: - Codable

    private var storageValue: String {
        displayName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let storedValue = try container.decode(String.self)

        self.init(legacyValue: storedValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storageValue)
    }
}
