import XCTest
@testable import MyWorkout

final class RestTimerRuleTests: XCTestCase {

    private func settings(
        compound: Int = 180,
        isolation: Int = 90,
        bodyweight: Int = 120
    ) -> UserSettings {
        UserSettings(
            unitSystem: .pounds,
            bodyWeightUnitSystem: .pounds,
            compoundRestSeconds: compound,
            isolationRestSeconds: isolation,
            bodyweightRestSeconds: bodyweight,
            oneRepMaxFormula: .epley,
            compoundIncrement: 5,
            isolationIncrement: 5,
            appearanceMode: .system,
            workoutSessionLayout: .classic
        )
    }

    func test_compound_returnsCompoundRestSeconds() {
        let result = RestTimerRule.seconds(for: .compound, settings: settings(compound: 180))
        XCTAssertEqual(result, 180)
    }

    func test_isolation_returnsIsolationRestSeconds() {
        let result = RestTimerRule.seconds(for: .isolation, settings: settings(isolation: 90))
        XCTAssertEqual(result, 90)
    }

    func test_bodyweight_returnsBodyweightRestSeconds() {
        let result = RestTimerRule.seconds(for: .bodyweight, settings: settings(bodyweight: 120))
        XCTAssertEqual(result, 120)
    }

    func test_customSettings_areRespectedPerExerciseType() {
        let customSettings = settings(compound: 240, isolation: 45, bodyweight: 60)

        XCTAssertEqual(RestTimerRule.seconds(for: .compound, settings: customSettings), 240)
        XCTAssertEqual(RestTimerRule.seconds(for: .isolation, settings: customSettings), 45)
        XCTAssertEqual(RestTimerRule.seconds(for: .bodyweight, settings: customSettings), 60)
    }

    func test_defaultSettings_matchExpectedRestPeriods() {
        XCTAssertEqual(RestTimerRule.seconds(for: .compound, settings: .defaults), 180)
        XCTAssertEqual(RestTimerRule.seconds(for: .isolation, settings: .defaults), 90)
        XCTAssertEqual(RestTimerRule.seconds(for: .bodyweight, settings: .defaults), 120)
    }
}
