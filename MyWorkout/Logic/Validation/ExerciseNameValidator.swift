import Foundation

enum ExerciseNameValidationResult: Equatable {
    case valid
    case empty
    case duplicate

    var message: String? {
        switch self {
        case .valid:
            return nil

        case .empty:
            return "Exercise name is required."

        case .duplicate:
            return "An exercise with this name already exists."
        }
    }
}

enum ExerciseNameValidator {
    private static let normalizationLocale =
        Locale(identifier: "en_US_POSIX")

    static func validate(
        _ name: String,
        existingExercises: [Exercise],
        excluding exerciseID: UUID? = nil
    ) -> ExerciseNameValidationResult {
        let normalizedName = normalize(name)

        guard !normalizedName.isEmpty else {
            return .empty
        }

        let hasDuplicate = existingExercises.contains { exercise in
            guard exercise.id != exerciseID else {
                return false
            }

            return normalize(exercise.name) == normalizedName
        }

        return hasDuplicate
            ? .duplicate
            : .valid
    }

    static func normalize(
        _ name: String
    ) -> String {
        name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .folding(
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive
                ],
                locale: normalizationLocale
            )
            .replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )
    }
}
