import XCTest
@testable import MyWorkout

final class TrendSmootherTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: referenceDate)!
    }

    func testEmptyInputProducesEmptyOutput() {
        XCTAssertTrue(TrendSmoother.movingAverage([]).isEmpty)
    }

    func testSinglePointIsItsOwnAverage() {
        let result = TrendSmoother.movingAverage([DatedValue(date: day(0), value: 80)])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].value, 80)
    }

    func testConstantValuesSmoothToTheSameConstant() {
        let points = (0..<10).map { DatedValue(date: day($0), value: 80) }

        let result = TrendSmoother.movingAverage(points, windowDays: 7)

        XCTAssertTrue(result.allSatisfy { $0.value == 80 })
    }

    func testSpikeIsDampenedRelativeToRawValue() {
        var points = (0..<6).map { DatedValue(date: day($0), value: 80) }
        points.append(DatedValue(date: day(6), value: 90)) // one-day spike

        let result = TrendSmoother.movingAverage(points, windowDays: 7)

        let smoothedSpikeValue = result.last!.value
        XCTAssertLessThan(smoothedSpikeValue, 90)
        XCTAssertGreaterThan(smoothedSpikeValue, 80)
    }

    func testOutputPreservesInputDatesAndCount() {
        let points = [day(0), day(2), day(5)].map { DatedValue(date: $0, value: 80) }

        let result = TrendSmoother.movingAverage(points)

        XCTAssertEqual(result.map(\.date), points.map(\.date))
    }

    func testWindowOfOneReturnsRawValuesUnchanged() {
        let points = [
            DatedValue(date: day(0), value: 80),
            DatedValue(date: day(1), value: 85)
        ]

        let result = TrendSmoother.movingAverage(points, windowDays: 1)

        XCTAssertEqual(result.map(\.value), [80, 85])
    }
}
