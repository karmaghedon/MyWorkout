import Foundation

enum ExerciseSource:
    String,
    Codable,
    CaseIterable,
    Identifiable,
    Hashable,
    Sendable {

    case builtIn
    case userCreated

    var id: Self {
        self
    }
}
