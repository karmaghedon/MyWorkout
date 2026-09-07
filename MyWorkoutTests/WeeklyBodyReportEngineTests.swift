import XCTest
@testable import MyWorkout

final class WeeklyBodyReportEngineTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: referenceDate)!
    }

    private func weight(_ offset: Int, _ value: Double) -> DatedValue {
        DatedValue(date: day(offset), value: value)
    }

    // MARK: - Empty input

    func testEmptyBodyMassProducesNoCards() {
        let cards = WeeklyBodyReportEngine.reportCards(bodyMass: [], waist: [], neck: [])

        XCTAssertTrue(cards.isEmpty)
    }

    // MARK: - Single sample

    func testSingleWeightSampleProducesOneCard() {
        let cards = WeeklyBodyReportEngine.reportCards(
            bodyMass: [weight(0, 80)],
            waist: [],
            neck: []
        )

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].weightMin, 80)
        XCTAssertEqual(cards[0].weightMax, 80)
        XCTAssertEqual(cards[0].weightAvg, 80)
        XCTAssertNil(cards[0].weightAvgDelta)
    }

    // MARK: - Normal cadence (exact 7-day boundaries)

    func testExactWeeklyBoundariesProduceOneCardPerBoundary() {
        let samples = [weight(0, 80), weight(7, 79), weight(14, 78)]

        let cards = WeeklyBodyReportEngine.reportCards(bodyMass: samples, waist: [], neck: [])

        XCTAssertEqual(cards.count, 3)
        XCTAssertEqual(cards[0].windowStart, day(0))
        XCTAssertEqual(cards[0].windowEnd, day(7))
        XCTAssertEqual(cards[1].windowStart, day(7))
        XCTAssertEqual(cards[1].windowEnd, day(14))
        XCTAssertEqual(cards[2].windowStart, day(14))

        // The boundary sample belongs to the window it starts, not the
        // one before it (half-open windows).
        XCTAssertEqual(cards[0].weightAvg, 80)
        XCTAssertEqual(cards[1].weightAvg, 79)
        XCTAssertEqual(cards[2].weightAvg, 78)

        XCTAssertEqual(cards[1].weightAvgDelta, 79 - 80)
        XCTAssertEqual(cards[2].weightAvgDelta, 78 - 79)
    }

    // MARK: - Sparse / irregular cadence

    func testSparseCadenceFoldsIntoSingleStretchedWindow() {
        // Two samples only 3 days apart — nowhere near a 7-day nominal
        // boundary, so both should fold into one window that stretches
        // to just past the last sample rather than producing a
        // degenerate second window.
        let samples = [weight(0, 80), weight(3, 79)]

        let cards = WeeklyBodyReportEngine.reportCards(bodyMass: samples, waist: [], neck: [])

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].weightMin, 79)
        XCTAssertEqual(cards[0].weightMax, 80)
        XCTAssertEqual(cards[0].weightAvg, 79.5)
    }

    func testIrregularCadenceMixesShortAndLongWindows() {
        // day 0 and day 2 are close together (fold into one window);
        // day 20 is far enough past the nominal boundary that it starts
        // its own new window.
        let samples = [weight(0, 80), weight(2, 79.5), weight(20, 76)]

        let cards = WeeklyBodyReportEngine.reportCards(bodyMass: samples, waist: [], neck: [])

        XCTAssertEqual(cards.count, 2)
        XCTAssertEqual(cards[0].windowStart, day(0))
        XCTAssertEqual(cards[0].weightAvg, (80 + 79.5) / 2)
        XCTAssertEqual(cards[1].windowStart, day(20))
        XCTAssertEqual(cards[1].weightAvg, 76)
    }

    // MARK: - Waist / neck aggregation

    func testWaistAndNeckUseLatestReadingNotAverage() {
        let bodyMass = [weight(0, 80), weight(1, 79.5), weight(7, 79)]
        let waist = [DatedValue(date: day(0), value: 90), DatedValue(date: day(3), value: 88)]
        let neck = [DatedValue(date: day(1), value: 40)]

        let cards = WeeklyBodyReportEngine.reportCards(bodyMass: bodyMass, waist: waist, neck: neck)

        XCTAssertEqual(cards.count, 2)
        // First window [day0, day7) contains both waist readings — latest wins.
        XCTAssertEqual(cards[0].waistLatest, 88)
        XCTAssertEqual(cards[0].neckLatest, 40)
        // Second window has no waist/neck readings at all.
        XCTAssertNil(cards[1].waistLatest)
        XCTAssertNil(cards[1].neckLatest)
    }

    func testWaistDeltaIsNilWhenEitherWindowIsMissingAReading() {
        let bodyMass = [weight(0, 80), weight(7, 79), weight(14, 78)]
        // Waist present in window 0 and window 2, absent in window 1.
        let waist = [DatedValue(date: day(0), value: 90), DatedValue(date: day(14), value: 87)]

        let cards = WeeklyBodyReportEngine.reportCards(bodyMass: bodyMass, waist: waist, neck: [])

        XCTAssertEqual(cards[0].waistLatest, 90)
        XCTAssertNil(cards[0].waistDelta)
        XCTAssertNil(cards[1].waistLatest)
        XCTAssertNil(cards[1].waistDelta)
        XCTAssertEqual(cards[2].waistLatest, 87)
        // Previous window (index 1) had no waist reading, so no delta.
        XCTAssertNil(cards[2].waistDelta)
    }
}
