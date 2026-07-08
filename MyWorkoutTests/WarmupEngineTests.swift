import XCTest
@testable import MyWorkout

final class WarmupEngineTests: XCTestCase {

    // MARK: - Barbell compound

    func test_barbellCompound_workingWeightEqualsBarWeight_returnsNoWarmups() {
        let warmups = WarmupEngine.generateWarmups(
            for: 45,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertTrue(warmups.isEmpty)
    }

    func test_barbellCompound_belowFirstBracket_onlyBarWarmups() {
        let warmups = WarmupEngine.generateWarmups(
            for: 70,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(warmups.map { ($0.weight, $0.reps) }.map(Pair.init), [
            Pair(45, 10), Pair(45, 8)
        ])
    }

    func test_barbellCompound_bracket95to120_addsOneRampSet() {
        let warmups = WarmupEngine.generateWarmups(
            for: 100,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(warmups.map { ($0.weight, $0.reps) }.map(Pair.init), [
            Pair(45, 10), Pair(45, 8), Pair(70, 5)
        ])
    }

    func test_barbellCompound_bracket120to160_addsTwoRampSets() {
        let warmups = WarmupEngine.generateWarmups(
            for: 140,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(warmups.map { ($0.weight, $0.reps) }.map(Pair.init), [
            Pair(45, 10), Pair(45, 8), Pair(85, 5), Pair(110, 3)
        ])
    }

    func test_barbellCompound_bracket160to210_addsThreeRampSets() {
        let warmups = WarmupEngine.generateWarmups(
            for: 180,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(warmups.map { ($0.weight, $0.reps) }.map(Pair.init), [
            Pair(45, 10), Pair(45, 8), Pair(90, 5), Pair(125, 3), Pair(155, 2)
        ])
    }

    func test_barbellCompound_bracket210Plus_addsFourRampSets() {
        let warmups = WarmupEngine.generateWarmups(
            for: 250,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(warmups.map { ($0.weight, $0.reps) }.map(Pair.init), [
            Pair(45, 10), Pair(45, 8), Pair(125, 5), Pair(175, 3), Pair(215, 2), Pair(230, 1)
        ])
    }

    // MARK: - Dumbbell compound

    func test_dumbbellCompound_belowMinimum_returnsNoWarmups() {
        let warmups = WarmupEngine.generateWarmups(
            for: 25,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertTrue(warmups.isEmpty)
    }

    func test_dumbbellCompound_belowSecondThreshold_onlyBaseWarmup() {
        let warmups = WarmupEngine.generateWarmups(
            for: 40,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertEqual(warmups.map { ($0.weight, $0.reps) }.map(Pair.init), [
            Pair(15, 10)
        ])
    }

    func test_dumbbellCompound_midRange_addsSecondWarmup() {
        let warmups = WarmupEngine.generateWarmups(
            for: 60,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertEqual(warmups.map { ($0.weight, $0.reps) }.map(Pair.init), [
            Pair(25, 10), Pair(35, 6)
        ])
    }

    func test_dumbbellCompound_highRange_addsThirdWarmup() {
        let warmups = WarmupEngine.generateWarmups(
            for: 100,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertEqual(warmups.map { ($0.weight, $0.reps) }.map(Pair.init), [
            Pair(40, 10), Pair(60, 6), Pair(75, 4)
        ])
    }

    // MARK: - Isolation

    func test_isolation_belowMinimum_returnsNoWarmups() {
        let warmups = WarmupEngine.generateWarmups(for: 20, exerciseType: .isolation)
        XCTAssertTrue(warmups.isEmpty)
    }

    func test_isolation_belowSecondThreshold_returnsOneWarmup() {
        let warmups = WarmupEngine.generateWarmups(for: 50, exerciseType: .isolation)

        XCTAssertEqual(warmups.map { ($0.weight, $0.reps) }.map(Pair.init), [
            Pair(25, 10)
        ])
    }

    func test_isolation_atOrAboveSecondThreshold_returnsTwoWarmups() {
        let warmups = WarmupEngine.generateWarmups(for: 80, exerciseType: .isolation)

        XCTAssertEqual(warmups.map { ($0.weight, $0.reps) }.map(Pair.init), [
            Pair(40, 10), Pair(60, 6)
        ])
    }

    // MARK: - Bodyweight

    func test_bodyweight_alwaysReturnsNoWarmups() {
        let warmups = WarmupEngine.generateWarmups(for: 0, exerciseType: .bodyweight)
        XCTAssertTrue(warmups.isEmpty)
    }
}

/// Small helper so warmup sets (weight, reps) can be compared with XCTAssertEqual
/// without needing WarmupSet itself to conform to Equatable.
private struct Pair: Equatable {
    let weight: Double
    let reps: Int

    init(_ weight: Double, _ reps: Int) {
        self.weight = weight
        self.reps = reps
    }

    init(_ tuple: (Double, Int)) {
        self.weight = tuple.0
        self.reps = tuple.1
    }
}
