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
        var weightSamplesResult: Result<[DatedValue], Error> = .success([])
        var waistSamplesResult: Result<[DatedValue], Error> = .success([])
        var bodyFatPercentSamplesResult: Result<[DatedValue], Error> = .success([])
    }

    private let state = ThreadSafeBox(State())

    var loggedWeights: [LoggedWeight] {
        state.read { $0.loggedWeights }
    }

    func setResult(_ result: Result<Void, Error>) {
        state.mutate { $0.result = result }
    }

    func setWeightSamplesResult(_ result: Result<[DatedValue], Error>) {
        state.mutate { $0.weightSamplesResult = result }
    }

    func setWaistSamplesResult(_ result: Result<[DatedValue], Error>) {
        state.mutate { $0.waistSamplesResult = result }
    }

    func setBodyFatPercentSamplesResult(_ result: Result<[DatedValue], Error>) {
        state.mutate { $0.bodyFatPercentSamplesResult = result }
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

    func weightSamples(since date: Date) async throws -> [DatedValue] {
        try state.read { try $0.weightSamplesResult.get() }
    }

    func waistSamples(since date: Date) async throws -> [DatedValue] {
        try state.read { try $0.waistSamplesResult.get() }
    }

    func bodyFatPercentSamples(since date: Date) async throws -> [DatedValue] {
        try state.read { try $0.bodyFatPercentSamplesResult.get() }
    }
}
