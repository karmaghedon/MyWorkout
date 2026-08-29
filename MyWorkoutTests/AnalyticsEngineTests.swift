import XCTest
@testable import MyWorkout

final class AnalyticsEngineTests: XCTestCase {
    private let engine = AnalyticsEngine()

    func testEmptyInputProducesEmptySnapshot() {
        let registry = ExerciseRegistry(
            sources: []
        )

        let snapshot = engine.makeSnapshot(
            logs: [],
            registry: registry
        )

        XCTAssertEqual(snapshot.totalSets, 0)
        XCTAssertTrue(
            snapshot.volumeByMuscleGroup.isEmpty
        )
        XCTAssertTrue(
            snapshot.personalRecords.isEmpty
        )
        XCTAssertTrue(
            snapshot.recoveryWarnings.isEmpty
        )
        XCTAssertTrue(
            snapshot.performanceWarnings.isEmpty
        )
    }
}
