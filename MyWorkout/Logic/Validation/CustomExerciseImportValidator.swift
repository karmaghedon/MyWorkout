import Foundation

enum CustomExerciseImportValidationResult: Equatable {
    case valid
    case duplicateIdentifier
    case reservedIdentifier
    case invalidName
    case duplicateName
    case reservedName

    var message: String? {
        switch self {
        case .valid:
            return nil

        case .duplicateIdentifier:
            return "The backup contains duplicate custom exercise identifiers."

        case .reservedIdentifier:
            return "A custom exercise conflicts with a built-in exercise identifier."

        case .invalidName:
            return "The backup contains a custom exercise without a valid name."

        case .duplicateName:
            return "The backup contains duplicate custom exercise names."

        case .reservedName:
            return "A custom exercise uses the name of a built-in exercise."
        }
    }
}

enum CustomExerciseImportValidator {
    static func validate(
        _ storedExercises: [StoredCustomExercise],
        reservedExercises: [Exercise]
    ) -> CustomExerciseImportValidationResult {
        let importedExercises =
            storedExercises.map(\.exercise)

        let importedIDs =
            importedExercises.map(\.id)

        guard Set(importedIDs).count == importedIDs.count else {
            return .duplicateIdentifier
        }

        let reservedIDs =
            Set(reservedExercises.map(\.id))

        guard importedIDs.allSatisfy({
            !reservedIDs.contains($0)
        }) else {
            return .reservedIdentifier
        }

        for exercise in importedExercises {
            guard ExerciseNameValidator.validate(
                exercise.name,
                existingExercises: []
            ) == .valid else {
                return .invalidName
            }
        }

        for index in importedExercises.indices {
            let exercise = importedExercises[index]

            let earlierExercises =
                Array(importedExercises[..<index])

            guard ExerciseNameValidator.validate(
                exercise.name,
                existingExercises: earlierExercises
            ) != .duplicate else {
                return .duplicateName
            }
        }

        for exercise in importedExercises {
            guard ExerciseNameValidator.validate(
                exercise.name,
                existingExercises: reservedExercises
            ) != .duplicate else {
                return .reservedName
            }
        }

        return .valid
    }
}
