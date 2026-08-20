import XCTest
@testable import MyWorkout

/// `completedWarmupWeights` and `extraWorkingSets` were added after every
/// active-workout snapshot on a real device was already persisted without
/// them. Confirms both default correctly (`[]` and `0`) when decoding a
/// payload that predates the fields, instead of throwing.
final class ExerciseSessionStateCodableTests: XCTestCase {

    func testDecodingPayloadWithoutNewFieldsDefaultsCorrectly() throws {
        let state = ExerciseSessionState(
            targetReps: 8,
            workingWeightPounds: 135,
            notes: "Test notes",
            completedWarmupWeights: [45, 95],
            extraWorkingSets: 2
        )

        let encoded = try JSONEncoder().encode(state)

        var payload = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        payload.removeValue(forKey: "completedWarmupWeights")
        payload.removeValue(forKey: "extraWorkingSets")

        let strippedData = try JSONSerialization.data(withJSONObject: payload)

        let decoded = try JSONDecoder().decode(
            ExerciseSessionState.self,
            from: strippedData
        )

        XCTAssertEqual(decoded.completedWarmupWeights, [])
        XCTAssertEqual(decoded.extraWorkingSets, 0)
        XCTAssertEqual(decoded.targetReps, 8)
        XCTAssertEqual(decoded.notes, "Test notes")
    }

    func testDecodingPayloadWithNewFieldsPreservesValues() throws {
        let state = ExerciseSessionState(
            completedWarmupWeights: [45, 95],
            extraWorkingSets: 2
        )

        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(
            ExerciseSessionState.self,
            from: encoded
        )

        XCTAssertEqual(decoded.completedWarmupWeights, [45, 95])
        XCTAssertEqual(decoded.extraWorkingSets, 2)
    }
}
