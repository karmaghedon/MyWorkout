import XCTest
@testable import MyWorkout

/// `targetSets` was added to `Exercise` after every built-in exercise,
/// custom exercise, saved template, and in-progress workout snapshot on a
/// real device was already persisted without it. `Exercise` has a
/// hand-written `init(from:)` specifically so `targetSets` can default via
/// `decodeIfPresent` instead of the compiler synthesizing a decoder that
/// requires the key on every decode — see `Exercise.swift`. This test
/// simulates that pre-change payload by encoding a real `Exercise` and
/// stripping the key back out, rather than hand-writing a JSON fixture
/// that could drift from the real encoded shape.
final class ExerciseCodableTests: XCTestCase {

    func testDecodingPayloadWithoutTargetSetsDefaultsToThree() throws {
        let exercise = Exercise(
            name: "Test Exercise",
            muscleGroup: .chest,
            equipment: .barbell,
            instructions: "Do the thing.",
            progressionRule: ProgressionRule(
                minReps: 8,
                maxReps: 10,
                increaseAmount: 5,
                deloadAmount: 5,
                stallLimit: 3
            ),
            exerciseType: .compound,
            progressionStrategy: .doubleProgression,
            targetSets: 5
        )

        let encoded = try JSONEncoder().encode(exercise)

        var payload = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        payload.removeValue(forKey: "targetSets")

        let strippedData = try JSONSerialization.data(withJSONObject: payload)

        let decoded = try JSONDecoder().decode(Exercise.self, from: strippedData)

        XCTAssertEqual(decoded.targetSets, 3)
        XCTAssertEqual(decoded.name, "Test Exercise")
    }

    func testDecodingPayloadWithTargetSetsPreservesValue() throws {
        let exercise = Exercise(
            name: "Test Exercise",
            muscleGroup: .back,
            equipment: .dumbbell,
            instructions: "Do the thing.",
            progressionRule: ProgressionRule(
                minReps: 8,
                maxReps: 10,
                increaseAmount: 5,
                deloadAmount: 5,
                stallLimit: 3
            ),
            exerciseType: .compound,
            progressionStrategy: .doubleProgression,
            targetSets: 5
        )

        let encoded = try JSONEncoder().encode(exercise)
        let decoded = try JSONDecoder().decode(Exercise.self, from: encoded)

        XCTAssertEqual(decoded.targetSets, 5)
    }
}
