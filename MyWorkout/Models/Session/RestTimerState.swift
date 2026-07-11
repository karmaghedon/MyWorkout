import Foundation

/// Domain state for an active exercise rest timer.
///
/// The start date and duration are the source of truth.
/// Remaining time is derived from those values instead of being persisted.
struct RestTimerState: Codable, Equatable {
    let exerciseID: UUID
    let startedAt: Date
    let durationSeconds: Int

    init(
        exerciseID: UUID,
        startedAt: Date = Date(),
        durationSeconds: Int
    ) {
        self.exerciseID = exerciseID
        self.startedAt = startedAt
        self.durationSeconds = max(0, durationSeconds)
    }

    func remainingSeconds(
        at date: Date = Date()
    ) -> Int {
        let elapsed = Int(
            date.timeIntervalSince(startedAt)
        )

        return max(
            0,
            durationSeconds - elapsed
        )
    }

    func isActive(
        at date: Date = Date()
    ) -> Bool {
        remainingSeconds(at: date) > 0
    }
}
