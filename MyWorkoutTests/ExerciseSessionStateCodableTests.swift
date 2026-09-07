import XCTest
@testable import MyWorkout

/// `completedWarmupKeys` and `extraWorkingSets` were added after every
/// active-workout snapshot on a real device was already persisted without
/// them. Confirms both default correctly (`[]` and `0`) when decoding a
/// payload that predates the fields, instead of throwing.
final class ExerciseSessionStateCodableTests: XCTestCase {

    func testDecodingPayloadWithoutNewFieldsDefaultsCorrectly() throws {
        let state = ExerciseSessionState(
            targetReps: 8,
            workingWeightPounds: 135,
            notes: "Test notes",
            completedWarmupKeys: [
                ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 10)
            ],
            extraWorkingSets: 2
        )

        let encoded = try JSONEncoder().encode(state)

        var payload = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        payload.removeValue(forKey: "completedWarmupKeys")
        payload.removeValue(forKey: "extraWorkingSets")

        let strippedData = try JSONSerialization.data(withJSONObject: payload)

        let decoded = try JSONDecoder().decode(
            ExerciseSessionState.self,
            from: strippedData
        )

        XCTAssertEqual(decoded.completedWarmupKeys, [])
        XCTAssertEqual(decoded.extraWorkingSets, 0)
        XCTAssertEqual(decoded.targetReps, 8)
        XCTAssertEqual(decoded.notes, "Test notes")
    }

    func testDecodingPayloadWithNewFieldsPreservesValues() throws {
        let state = ExerciseSessionState(
            completedWarmupKeys: [
                ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 10),
                ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 8)
            ],
            extraWorkingSets: 2
        )

        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(
            ExerciseSessionState.self,
            from: encoded
        )

        XCTAssertEqual(
            decoded.completedWarmupKeys,
            [
                ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 10),
                ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 8)
            ]
        )
        XCTAssertEqual(decoded.extraWorkingSets, 2)
    }

    /// The whole point of switching from a weight-only key to
    /// weight+reps: two warm-up sets at the same weight but different
    /// reps must produce distinct keys, or completing one would silently
    /// complete the other too (see `WarmupEngine`'s barbell ramp, which
    /// starts with two sets at the empty-bar weight).
    func testWarmupKeyDistinguishesSameWeightDifferentReps() {
        let tenRepKey = ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 10)
        let eightRepKey = ExerciseSessionState.warmupKey(index: 0, weight: 45, reps: 8)

        XCTAssertNotEqual(tenRepKey, eightRepKey)
    }
}
