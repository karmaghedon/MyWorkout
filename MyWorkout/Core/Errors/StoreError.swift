import Foundation

enum StoreOperation: String, Codable {
    case loading
    case saving
    case deleting

    var displayName: String {
        switch self {
        case .loading:
            return "Loading"

        case .saving:
            return "Saving"

        case .deleting:
            return "Deleting"
        }
    }
}

struct StoreError: Identifiable, Equatable {
    let id: UUID
    let operation: StoreOperation
    let message: String

    init(
        id: UUID = UUID(),
        operation: StoreOperation,
        message: String
    ) {
        self.id = id
        self.operation = operation
        self.message = message
    }
}
