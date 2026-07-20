import SwiftUI

struct WorkoutTabPresentation: Equatable {
    let title: LocalizedStringKey
    let statusText: String?
    let accessibilityLabel: String

    static let inactive = WorkoutTabPresentation(
        title: "Workout",
        statusText: nil,
        accessibilityLabel: "Workout"
    )

    static func active(
        restSecondsRemaining: Int
    ) -> WorkoutTabPresentation {
        guard restSecondsRemaining > 0 else {
            return WorkoutTabPresentation(
                title: "Resume",
                statusText: nil,
                accessibilityLabel: "Resume active workout"
            )
        }

        let formattedTime = formatDuration(
            restSecondsRemaining
        )

        return WorkoutTabPresentation(
            title: "Resume",
            statusText: formattedTime,
            accessibilityLabel:
                "Resume active workout. Rest timer "
                + formattedTime
                + " remaining."
        )
    }

    private static func formatDuration(
        _ seconds: Int
    ) -> String {
        let safeSeconds = max(0, seconds)
        let minutes = safeSeconds / 60
        let remainingSeconds = safeSeconds % 60

        return String(
            format: "%02d:%02d",
            minutes,
            remainingSeconds
        )
    }
}
