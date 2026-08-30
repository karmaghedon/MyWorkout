import Foundation
@testable import MyWorkout

/// Never construct the real `HKHealthStore`-backed
/// `ActivityHealthKitService` in a test — it can pop real permission
/// dialogs on the physical device XCTest runs against in this
/// environment (CoreSimulator is broken here, so `xcodebuild test` runs
/// against the connected iPhone, not a sandboxed simulator).
final class MockActivityHealthKitService:
    ActivityHealthKitServicing,
    @unchecked Sendable {

    private struct State {
        var result: Result<[DatedValue], Error> = .success([])
    }

    private let state = ThreadSafeBox(State())

    func setResult(_ result: Result<[DatedValue], Error>) {
        state.mutate { $0.result = result }
    }

    func dailyStepTotals(since date: Date) async throws -> [DatedValue] {
        try state.read { try $0.result.get() }
    }
}
