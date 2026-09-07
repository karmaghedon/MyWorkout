import Foundation
@testable import MyWorkout

/// Never construct the real `HKHealthStore`-backed
/// `NutritionHealthKitService` in a test — it can pop real permission
/// dialogs and write real rows into the user's actual Health app on the
/// physical device XCTest runs against in this environment (CoreSimulator
/// is broken here, so `xcodebuild test` runs against the connected
/// iPhone, not a sandboxed simulator).
final class MockNutritionHealthKitService:
    NutritionHealthKitServicing,
    @unchecked Sendable {

    struct LoggedDailyTotals: Equatable {
        let proteinG: Double
        let carbsG: Double
        let fatG: Double
        let calories: Double
        let date: Date
    }

    enum MockError: Error {
        case saveFailed
    }

    private struct State {
        var result: Result<Void, Error> = .success(())
        var loggedDailyTotals: [LoggedDailyTotals] = []
    }

    private let state = ThreadSafeBox(State())

    var loggedDailyTotals: [LoggedDailyTotals] {
        state.read { $0.loggedDailyTotals }
    }

    func setResult(_ result: Result<Void, Error>) {
        state.mutate { $0.result = result }
    }

    func logDailyTotals(
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        calories: Double,
        date: Date
    ) async throws {
        let result: Result<Void, Error> = state.mutate {
            $0.loggedDailyTotals.append(
                LoggedDailyTotals(proteinG: proteinG, carbsG: carbsG, fatG: fatG, calories: calories, date: date)
            )
            return $0.result
        }

        try result.get()
    }
}
