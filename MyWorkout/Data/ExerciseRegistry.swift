import Foundation

struct ExerciseRegistry {
    private let exercisesByID: [UUID: Exercise]
    private let exercisesByNormalizedName: [String: Exercise]

    enum ExerciseResolution {
        case exercise(Exercise)
        case historical(HistoricalExerciseReference)
    }
    
    private let historicalReferencesByID: [
        String: HistoricalExerciseReference
    ]
    
    init(
        sources: [any ExerciseProviding],
        historicalReferences: [
            HistoricalExerciseReference
        ] = []
    ) {
        let mergedExercises = Self.merge(
            sources.flatMap(\.exercises)
        )

        exercisesByID = Dictionary(
            uniqueKeysWithValues: mergedExercises.map {
                ($0.id, $0)
            }
        )

        exercisesByNormalizedName = Dictionary(
            uniqueKeysWithValues: mergedExercises.map {
                (
                    Self.normalizedName($0.name),
                    $0
                )
            }
        )

        historicalReferencesByID = Dictionary(
            uniqueKeysWithValues: historicalReferences.map {
                ($0.stableID, $0)
            }
        )
    }
    


    var exercises: [Exercise] {
        exercisesByID.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name)
                == .orderedAscending
        }
    }

    func resolve(
        id: UUID?,
        name: String
    ) -> ExerciseResolution? {
        if let exercise = exercise(
            id: id,
            name: name
        ) {
            return .exercise(exercise)
        }

        let key =
            id?.uuidString
            ?? Self.normalizedName(name)

        guard let reference =
            historicalReferencesByID[key] else {
            return nil
        }

        return .historical(reference)
    }
    
    func exercise(id: UUID) -> Exercise? {
        exercisesByID[id]
    }

    func exercise(
        id: UUID?,
        name: String
    ) -> Exercise? {
        if let id,
           let exercise = exercisesByID[id] {
            return exercise
        }

        return exercisesByNormalizedName[
            Self.normalizedName(name)
        ]
    }

    private static func merge(
        _ exercises: [Exercise]
    ) -> [Exercise] {
        var result: [UUID: Exercise] = [:]

        for exercise in exercises {
            result[exercise.id] = exercise
        }

        return Array(result.values)
    }

    private static func normalizedName(
        _ name: String
    ) -> String {
        name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
    }
}
