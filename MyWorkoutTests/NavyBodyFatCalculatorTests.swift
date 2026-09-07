import XCTest
@testable import MyWorkout

final class NavyBodyFatCalculatorTests: XCTestCase {

    // MARK: - Male

    func testMaleEstimateFallsWithinPlausibleRange() throws {
        let result = NavyBodyFatCalculator.estimate(
            sex: .male,
            heightCm: 178,
            waistCm: 86,
            neckCm: 38,
            hipCm: nil
        )

        let estimate = try XCTUnwrap(result)
        XCTAssertGreaterThan(estimate, 0)
        XCTAssertLessThan(estimate, 50)
    }

    func testMaleEstimateIncreasesAsWaistGrowsRelativeToNeck() {
        let lowerWaist = try! XCTUnwrap(
            NavyBodyFatCalculator.estimate(sex: .male, heightCm: 178, waistCm: 80, neckCm: 38, hipCm: nil)
        )
        let higherWaist = try! XCTUnwrap(
            NavyBodyFatCalculator.estimate(sex: .male, heightCm: 178, waistCm: 100, neckCm: 38, hipCm: nil)
        )

        XCTAssertGreaterThan(higherWaist, lowerWaist)
    }

    func testMaleEstimateReturnsNilWhenWaistDoesNotExceedNeck() {
        let result = NavyBodyFatCalculator.estimate(
            sex: .male,
            heightCm: 178,
            waistCm: 38,
            neckCm: 38,
            hipCm: nil
        )

        XCTAssertNil(result)
    }

    // MARK: - Female

    func testFemaleEstimateFallsWithinPlausibleRange() throws {
        let result = NavyBodyFatCalculator.estimate(
            sex: .female,
            heightCm: 165,
            waistCm: 71,
            neckCm: 32,
            hipCm: 97
        )

        let estimate = try XCTUnwrap(result)
        XCTAssertGreaterThan(estimate, 0)
        XCTAssertLessThan(estimate, 60)
    }

    func testFemaleEstimateReturnsNilWithoutHipMeasurement() {
        let result = NavyBodyFatCalculator.estimate(
            sex: .female,
            heightCm: 165,
            waistCm: 71,
            neckCm: 32,
            hipCm: nil
        )

        XCTAssertNil(result)
    }

    func testFemaleEstimateIncreasesAsWaistPlusHipGrowsRelativeToNeck() {
        let smaller = try! XCTUnwrap(
            NavyBodyFatCalculator.estimate(sex: .female, heightCm: 165, waistCm: 65, neckCm: 32, hipCm: 90)
        )
        let larger = try! XCTUnwrap(
            NavyBodyFatCalculator.estimate(sex: .female, heightCm: 165, waistCm: 85, neckCm: 32, hipCm: 110)
        )

        XCTAssertGreaterThan(larger, smaller)
    }

    // MARK: - Shared guards

    func testReturnsNilForNonPositiveHeight() {
        let result = NavyBodyFatCalculator.estimate(
            sex: .male,
            heightCm: 0,
            waistCm: 86,
            neckCm: 38,
            hipCm: nil
        )

        XCTAssertNil(result)
    }

    // MARK: - fillGaps

    private let calendar = Calendar(identifier: .gregorian)
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: referenceDate)!
    }

    func testFillGapsReturnsActualUnchangedWhenSexOrHeightIsMissing() {
        let actual = [DatedValue(date: day(0), value: 18)]
        let waist = [DatedValue(date: day(1), value: 86)]
        let neck = [DatedValue(date: day(1), value: 38)]

        let result = NavyBodyFatCalculator.fillGaps(
            actual: actual,
            waist: waist,
            neck: neck,
            hip: [],
            sex: nil,
            heightCm: 178
        )

        XCTAssertEqual(result, actual)
    }

    func testFillGapsAddsEstimateForDayWithNoActualReading() {
        let waist = [DatedValue(date: day(0), value: 86)]
        let neck = [DatedValue(date: day(0), value: 38)]

        let result = NavyBodyFatCalculator.fillGaps(
            actual: [],
            waist: waist,
            neck: neck,
            hip: [],
            sex: .male,
            heightCm: 178
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(calendar.startOfDay(for: result[0].date), calendar.startOfDay(for: day(0)))
    }

    func testFillGapsNeverOverridesAnActualReadingForTheSameDay() {
        let actual = [DatedValue(date: day(0), value: 15)]
        let waist = [DatedValue(date: day(0), value: 86)]
        let neck = [DatedValue(date: day(0), value: 38)]

        let result = NavyBodyFatCalculator.fillGaps(
            actual: actual,
            waist: waist,
            neck: neck,
            hip: [],
            sex: .male,
            heightCm: 178
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].value, 15)
    }

    func testFillGapsSkipsFemaleDayMissingHipMeasurement() {
        let waist = [DatedValue(date: day(0), value: 71)]
        let neck = [DatedValue(date: day(0), value: 32)]

        let result = NavyBodyFatCalculator.fillGaps(
            actual: [],
            waist: waist,
            neck: neck,
            hip: [],
            sex: .female,
            heightCm: 165
        )

        XCTAssertTrue(result.isEmpty)
    }

    func testFillGapsSkipsDayMissingEitherWaistOrNeck() {
        let waist = [DatedValue(date: day(0), value: 86)]
        // No neck reading on day 0.

        let result = NavyBodyFatCalculator.fillGaps(
            actual: [],
            waist: waist,
            neck: [],
            hip: [],
            sex: .male,
            heightCm: 178
        )

        XCTAssertTrue(result.isEmpty)
    }
}
