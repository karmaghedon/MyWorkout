import SwiftUI

/// Shared design tokens for MyWorkout.
///
/// Centralizing color, spacing, radius, and type choices here means every
/// screen pulls from the same palette instead of each view inventing its
/// own. Start new screens by reaching for these instead of raw values.
enum AppTheme {

    // MARK: - Color

    /// Primary action / energy color. Used for the things a lifter taps
    /// mid-set: Log Set, the rest timer, active states. Kept to one
    /// saturated accent so it stays meaningful — if everything is tinted,
    /// nothing reads as "the important button."
    static let accent = Color(red: 1.0, green: 0.34, blue: 0.2) // ember orange

    /// Soft tint of the accent for backgrounds behind accent-colored text
    /// (suggestion banners, rest timer badge, set-number chips).
    static let accentMuted = Color(red: 1.0, green: 0.34, blue: 0.2).opacity(0.15)

    static let success = Color(red: 0.20, green: 0.70, blue: 0.45)

    /// Adaptive surfaces — these automatically flip for light/dark mode.
    static let cardBackground = Color(.secondarySystemBackground)
    static let subtleFill = Color(.tertiarySystemFill)
    static let groupedBackground = Color(.systemGroupedBackground)

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // MARK: - Corner Radius

    enum Radius {
        static let control: CGFloat = 10
        static let card: CGFloat = 18
    }

    // MARK: - Typography

    enum Typography {
        /// Big, glanceable numbers — rest timer, weight, reps. Rounded
        /// design feels less clinical than the system default for a
        /// fitness context.
        static func numeric(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        static let sectionTitle = Font.system(.title3, design: .rounded).weight(.bold)
        static let label = Font.system(.subheadline, design: .rounded).weight(.semibold)
        static let caption = Font.system(.caption, design: .rounded)
        static let eyebrow = Font.system(.caption2, design: .rounded).weight(.bold)
    }
}
