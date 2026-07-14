import XCTest
@testable import MyWorkout

final class PersistedEnvelopeTests: XCTestCase {
    private struct TestPayload: Codable, Equatable {
        let name: String
        let count: Int
    }

    func testRoundTripPreservesVersionAndPayload() throws {
        let envelope = PersistedEnvelope(
            schemaVersion: 1,
            payload: TestPayload(
                name: "Test",
                count: 3
            )
        )

        let data = try JSONEncoder().encode(envelope)

        let decoded = try JSONDecoder().decode(
            PersistedEnvelope<TestPayload>.self,
            from: data
        )

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.payload, envelope.payload)
    }
}
