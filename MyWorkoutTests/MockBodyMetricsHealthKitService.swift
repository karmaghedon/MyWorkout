import Foundation
@testable import MyWorkout

/// Never construct the real `HKHealthStore`-backed
/// `BodyMetricsHealthKitService` in a test — it can pop real permission
/// dialogs and write real rows into the user's actual Health app on the
/// physical device XCTest runs against in this environment (CoreSimulator
/// is broken here, so `xcodebuild test` runs against the connected
/// iPhone, not a sandboxed simulator).
final class MockBodyMetricsHealthKitService:
    BodyMetricsHealthKitServicing,
    @unchecked Sendable {

    struct LoggedWeight: Equatable {
        let kg: Double
        let bodyFatPercent: Double?
        let waistCm: Double?
        let date: Date
    }

    enum MockError: Error {
        case saveFailed
    }

    private struct State {
        var result: Result<Void, Error> = .success(())
        var loggedWeights: [LoggedWeight] = []
    }

    private let state = ThreadSafeBox(State())

    var loggedWeights: [LoggedWeight] {
        state.read { $0.loggedWeights }
    }

    func setResult(_ result: Result<Void, Error>) {
        state.mutate { $0.result = result }
    }

    func logWeight(
        kg: Double,
        bodyFatPercent: Double?,
        waistCm: Double?,
        date: Date
    ) async throws {
        let result: Result<Void, Error> = state.mutate {
            $0.loggedWeights.append(
                LoggedWeight(kg: kg, bodyFatPercent: bodyFatPercent, waistCm: waistCm, date: date)
            )
            return $0.result
        }

        try result.get()
    }
}
