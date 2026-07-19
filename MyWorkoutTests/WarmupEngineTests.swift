import XCTest
@testable import MyWorkout

final class WarmupEngineTests: XCTestCase {

    // MARK: - Barbell Compound

    func testBarbellCompoundWorkingWeightEqualsBarWeightReturnsNoWarmups() {
        let warmups = WarmupEngine.generateWarmups(
            for: 45,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertTrue(warmups.isEmpty)
    }

    func testBarbellCompoundWorkingWeightBelowBarWeightReturnsNoWarmups() {
        let warmups = WarmupEngine.generateWarmups(
            for: 40,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertTrue(warmups.isEmpty)
    }

    func testBarbellCompoundBelowFirstBracketReturnsOnlyBarWarmups() {
        let warmups = WarmupEngine.generateWarmups(
            for: 70,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(45, 10),
                Pair(45, 8)
            ]
        )
    }

    func testBarbellCompoundAt95AddsOneRampSet() {
        let warmups = WarmupEngine.generateWarmups(
            for: 95,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(45, 10),
                Pair(45, 8),
                Pair(65, 5)
            ]
        )
    }

    func testBarbellCompoundBelow120UsesOneRampSet() {
        let warmups = WarmupEngine.generateWarmups(
            for: 119,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(warmups.count, 3)
        XCTAssertEqual(warmups.last?.reps, 5)
    }

    func testBarbellCompoundAt120AddsTwoRampSets() {
        let warmups = WarmupEngine.generateWarmups(
            for: 120,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(45, 10),
                Pair(45, 8),
                Pair(70, 5),
                Pair(95, 3)
            ]
        )
    }

    func testBarbellCompoundAt160AddsThreeRampSets() {
        let warmups = WarmupEngine.generateWarmups(
            for: 160,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(45, 10),
                Pair(45, 8),
                Pair(80, 5),
                Pair(110, 3),
                Pair(135, 2)
            ]
        )
    }

    func testBarbellCompoundAt210AddsFourRampSets() {
        let warmups = WarmupEngine.generateWarmups(
            for: 210,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(45, 10),
                Pair(45, 8),
                Pair(105, 5),
                Pair(145, 3),
                Pair(180, 2),
                Pair(195, 1)
            ]
        )
    }

    func testBarbellCompoundHighRangeMatchesExpectedRamp() {
        let warmups = WarmupEngine.generateWarmups(
            for: 250,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(45, 10),
                Pair(45, 8),
                Pair(125, 5),
                Pair(175, 3),
                Pair(215, 2),
                Pair(230, 1)
            ]
        )
    }

    func testBarbellCompoundNeverProducesWeightAboveOrEqualToWorkingWeight() {
        let workingWeights: [Double] = [
            46, 70, 95, 120, 160, 210, 250
        ]

        for workingWeight in workingWeights {
            let warmups = WarmupEngine.generateWarmups(
                for: workingWeight,
                exerciseType: .compound,
                usesBarbell: true,
                barbellWeight: 45
            )

            XCTAssertTrue(
                warmups.allSatisfy {
                    $0.weight < workingWeight
                },
                "Warmups must remain below \(workingWeight)"
            )
        }
    }

    func testBarbellCompoundRampWeightsIncreaseAfterEmptyBarSets() {
        let warmups = WarmupEngine.generateWarmups(
            for: 250,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        let rampWeights = warmups
            .dropFirst(2)
            .map(\.weight)

        XCTAssertTrue(
            isStrictlyIncreasing(rampWeights)
        )
    }

    func testBarbellCompoundDoesNotDuplicateRampWeights() {
        let warmups = WarmupEngine.generateWarmups(
            for: 250,
            exerciseType: .compound,
            usesBarbell: true,
            barbellWeight: 45
        )

        let rampWeights = warmups
            .dropFirst(2)
            .map(\.weight)

        XCTAssertEqual(
            Set(rampWeights).count,
            rampWeights.count
        )
    }

    // MARK: - Dumbbell Compound

    func testDumbbellCompoundBelowMinimumReturnsNoWarmups() {
        let warmups = WarmupEngine.generateWarmups(
            for: 25,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertTrue(warmups.isEmpty)
    }

    func testDumbbellCompoundAt30ReturnsBaseWarmup() {
        let warmups = WarmupEngine.generateWarmups(
            for: 30,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(10, 10)
            ]
        )
    }

    func testDumbbellCompoundBelowSecondThresholdReturnsBaseWarmup() {
        let warmups = WarmupEngine.generateWarmups(
            for: 40,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(15, 10)
            ]
        )
    }

    func testDumbbellCompoundAt50AddsSecondWarmup() {
        let warmups = WarmupEngine.generateWarmups(
            for: 50,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(20, 10),
                Pair(30, 6)
            ]
        )
    }

    func testDumbbellCompoundAt80AddsThirdWarmup() {
        let warmups = WarmupEngine.generateWarmups(
            for: 80,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(30, 10),
                Pair(50, 6),
                Pair(60, 4)
            ]
        )
    }

    func testDumbbellCompoundHighRangeMatchesExpectedRamp() {
        let warmups = WarmupEngine.generateWarmups(
            for: 100,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(40, 10),
                Pair(60, 6),
                Pair(75, 4)
            ]
        )
    }

    func testDumbbellCompoundWarmupsIncreaseAndStayBelowWorkingWeight() {
        let warmups = WarmupEngine.generateWarmups(
            for: 100,
            exerciseType: .compound,
            usesBarbell: false
        )

        XCTAssertTrue(
            isStrictlyIncreasing(
                warmups.map(\.weight)
            )
        )
        XCTAssertTrue(
            warmups.allSatisfy {
                $0.weight < 100
            }
        )
    }

    // MARK: - Isolation

    func testIsolationBelowMinimumReturnsNoWarmups() {
        let warmups = WarmupEngine.generateWarmups(
            for: 20,
            exerciseType: .isolation
        )

        XCTAssertTrue(warmups.isEmpty)
    }

    func testIsolationAt30ReturnsOneWarmup() {
        let warmups = WarmupEngine.generateWarmups(
            for: 30,
            exerciseType: .isolation
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(15, 10)
            ]
        )
    }

    func testIsolationBelow60ReturnsOneWarmup() {
        let warmups = WarmupEngine.generateWarmups(
            for: 50,
            exerciseType: .isolation
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(25, 10)
            ]
        )
    }

    func testIsolationAt60ReturnsTwoWarmups() {
        let warmups = WarmupEngine.generateWarmups(
            for: 60,
            exerciseType: .isolation
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(30, 10),
                Pair(45, 6)
            ]
        )
    }

    func testIsolationHighRangeReturnsTwoWarmups() {
        let warmups = WarmupEngine.generateWarmups(
            for: 80,
            exerciseType: .isolation
        )

        XCTAssertEqual(
            pairs(from: warmups),
            [
                Pair(40, 10),
                Pair(60, 6)
            ]
        )
    }

    // MARK: - Bodyweight

    func testBodyweightAlwaysReturnsNoWarmups() {
        let workingWeights: [Double] = [
            -10, 0, 50, 100
        ]

        for workingWeight in workingWeights {
            let warmups = WarmupEngine.generateWarmups(
                for: workingWeight,
                exerciseType: .bodyweight
            )

            XCTAssertTrue(warmups.isEmpty)
        }
    }

    // MARK: - General Invariants

    func testGeneratedWarmupsNeverUseNegativeWeights() {
        let scenarios: [
            (
                weight: Double,
                type: ExerciseType,
                usesBarbell: Bool
            )
        ] = [
            (-10, .compound, true),
            (-10, .compound, false),
            (-10, .isolation, false),
            (0, .compound, true),
            (0, .compound, false),
            (0, .isolation, false)
        ]

        for scenario in scenarios {
            let warmups = WarmupEngine.generateWarmups(
                for: scenario.weight,
                exerciseType: scenario.type,
                usesBarbell: scenario.usesBarbell,
                barbellWeight: 45
            )

            XCTAssertTrue(
                warmups.allSatisfy {
                    $0.weight >= 0
                }
            )
        }
    }

    func testGeneratedWarmupsAlwaysUsePositiveReps() {
        let warmups =
            WarmupEngine.generateWarmups(
                for: 250,
                exerciseType: .compound,
                usesBarbell: true,
                barbellWeight: 45
            )
            + WarmupEngine.generateWarmups(
                for: 100,
                exerciseType: .compound,
                usesBarbell: false
            )
            + WarmupEngine.generateWarmups(
                for: 80,
                exerciseType: .isolation
            )

        XCTAssertTrue(
            warmups.allSatisfy {
                $0.reps > 0
            }
        )
    }

    func testGeneratedWarmupsUseOnlyApprovedRepCounts() {
        let approvedRepCounts: Set<Int> = [
            10, 8, 6, 5, 4, 3, 2, 1
        ]

        let warmups =
            WarmupEngine.generateWarmups(
                for: 250,
                exerciseType: .compound,
                usesBarbell: true,
                barbellWeight: 45
            )
            + WarmupEngine.generateWarmups(
                for: 100,
                exerciseType: .compound,
                usesBarbell: false
            )
            + WarmupEngine.generateWarmups(
                for: 80,
                exerciseType: .isolation
            )

        XCTAssertTrue(
            warmups.allSatisfy {
                approvedRepCounts.contains(
                    $0.reps
                )
            }
        )
    }

    // MARK: - Helpers

    private func pairs(
        from warmups: [WarmupSet]
    ) -> [Pair] {
        warmups.map {
            Pair(
                $0.weight,
                $0.reps
            )
        }
    }

    private func isStrictlyIncreasing(
        _ values: [Double]
    ) -> Bool {
        zip(
            values,
            values.dropFirst()
        )
        .allSatisfy(<)
    }
}

private struct Pair: Equatable {
    let weight: Double
    let reps: Int

    init(
        _ weight: Double,
        _ reps: Int
    ) {
        self.weight = weight
        self.reps = reps
    }
}
