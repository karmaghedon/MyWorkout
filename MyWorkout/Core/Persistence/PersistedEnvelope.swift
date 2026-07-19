import Foundation

struct PersistedEnvelope<Value: Codable>: Codable {
    let schemaVersion: Int
    let payload: Value

    init(
        schemaVersion: Int,
        payload: Value
    ) {
        precondition(
            schemaVersion > 0,
            "Schema version must be greater than zero."
        )

        self.schemaVersion = schemaVersion
        self.payload = payload
    }
}
