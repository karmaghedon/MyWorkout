import Foundation

/// Which U.S. Navy body-fat formula variant applies — that is the only
/// reason this exists in the app. Not a general-purpose identity field.
enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male
    case female

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}
