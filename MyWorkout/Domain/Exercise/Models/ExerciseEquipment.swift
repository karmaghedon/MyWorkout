import Foundation

/// Equipment required to perform an exercise.
///
/// Known equipment uses type-safe cases.
/// Unknown or future values are preserved through `.other`.
enum ExerciseEquipment: Hashable, Identifiable, Comparable, Codable {
    case barbell
    case dumbbell
    case bodyweight
    case kettlebellOrDumbbell
    case cableOrBand
    case other(String)

    var id: String {
        storageValue
    }

    var displayName: String {
        switch self {
        case .barbell:
            return "Barbell"

        case .dumbbell:
            return "Dumbbell"

        case .bodyweight:
            return "Bodyweight"

        case .kettlebellOrDumbbell:
            return "Kettlebell/Dumbbell"

        case .cableOrBand:
            return "Cable/Band"

        case .other(let value):
            return value
        }
    }

    var usesBarbell: Bool {
        switch self {
        case .barbell:
            return true

        case .dumbbell,
             .bodyweight,
             .kettlebellOrDumbbell,
             .cableOrBand,
             .other:
            return false
        }
    }

    var systemImage: String {
        switch self {
        case .barbell:
            return "dumbbell.fill"

        case .dumbbell,
             .kettlebellOrDumbbell:
            return "dumbbell"

        case .bodyweight:
            return "figure.strengthtraining.traditional"

        case .cableOrBand,
             .other:
            return "figure.strengthtraining.functional"
        }
    }

    static func < (
        lhs: ExerciseEquipment,
        rhs: ExerciseEquipment
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
        case "barbell":
            self = .barbell

        case "dumbbell", "dumbbells":
            self = .dumbbell

        case "bodyweight", "body weight":
            self = .bodyweight

        case "kettlebell/dumbbell",
             "dumbbell/kettlebell":
            self = .kettlebellOrDumbbell

        case "cable/band",
             "band/cable",
             "resistance band":
            self = .cableOrBand

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
