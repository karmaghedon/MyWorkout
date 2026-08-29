import Foundation

struct HistoricalExerciseReference: Identifiable, Hashable {
    let id: UUID?
    let name: String

    var stableID: String {
        id?.uuidString ?? normalizedName
    }

    private var normalizedName: String {
        name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
    }
}
