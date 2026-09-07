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
    ///
    /// Custom brand colors don't get automatic Increase Contrast adjustment
    /// the way system colors do, so accent and success carry explicit
    /// high-contrast variants via `dynamicColor`.
    static let accent = dynamicColor(
        light: UIColor(red: 1.0, green: 0.34, blue: 0.2, alpha: 1),
        dark: UIColor(red: 1.0, green: 0.34, blue: 0.2, alpha: 1),
        lightHighContrast: UIColor(red: 0.80, green: 0.16, blue: 0.02, alpha: 1),
        darkHighContrast: UIColor(red: 1.0, green: 0.52, blue: 0.38, alpha: 1)
    ) // ember orange

    /// Soft tint of the accent for backgrounds behind accent-colored text
    /// (suggestion banners, rest timer badge, set-number chips).
    static let accentMuted = accent.opacity(0.15)

    static let success = dynamicColor(
        light: UIColor(red: 0.20, green: 0.70, blue: 0.45, alpha: 1),
        dark: UIColor(red: 0.20, green: 0.70, blue: 0.45, alpha: 1),
        lightHighContrast: UIColor(red: 0.02, green: 0.42, blue: 0.24, alpha: 1),
        darkHighContrast: UIColor(red: 0.38, green: 0.86, blue: 0.58, alpha: 1)
    )

    /// System semantic colors below already adapt for light/dark mode and
    /// Increase Contrast — no custom dynamic handling needed.
    static let warning = Color(.systemOrange)
    static let error = Color(.systemRed)

    /// Content color for text/icons drawn directly on a solid `accent`
    /// fill (primary buttons, the FAB). Must be dynamic, not fixed: the
    /// base accent's light-mode Increase Contrast variant (0.80, 0.16,
    /// 0.02) is dark enough that black text on it only measures 3.88:1,
    /// below the 4.5:1 WCAG AA floor, while white on that same variant
    /// measures 5.41:1 and passes. Every other variant (light/dark
    /// normal at 6.65:1, dark high-contrast at 8.76:1) is well served by
    /// black, so white is the exception rather than the rule.
    static let onAccentFill = dynamicColor(
        light: .black,
        dark: .black,
        lightHighContrast: .white,
        darkHighContrast: .black
    )

    /// Adaptive surfaces — these automatically flip for light/dark mode.
    static let background = Color(.systemBackground)
    static let cardBackground = Color(.secondarySystemBackground)
    static let subtleFill = Color(.tertiarySystemFill)
    static let groupedBackground = Color(.systemGroupedBackground)

    /// Text hierarchy below the primary label color.
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)

    /// Builds a `Color` that swaps in a higher-contrast variant when the
    /// user has Increase Contrast enabled, in addition to the usual
    /// light/dark split. Use for brand colors that have no system
    /// equivalent to inherit that behavior from automatically.
    private static func dynamicColor(
        light: UIColor,
        dark: UIColor,
        lightHighContrast: UIColor,
        darkHighContrast: UIColor
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let highContrast = traits.accessibilityContrast == .high
            switch traits.userInterfaceStyle {
            case .dark:
                return highContrast ? darkHighContrast : dark
            default:
                return highContrast ? lightHighContrast : light
            }
        })
    }

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

    // MARK: - Stroke Width

    enum StrokeWidth {
        /// Thin borders and dividers (e.g. a validation-state card outline).
        static let hairline: CGFloat = 1
        /// Progress rings and other emphasized circular strokes.
        static let ring: CGFloat = 4
    }

    // MARK: - Elevation

    enum Elevation {
        /// A single, restrained shadow spec for surfaces that need to lift
        /// off the background (e.g. a floating action button). The design
        /// language favors flat, calm surfaces — most cards should separate
        /// with `cardBackground` alone rather than a shadow. Reach for this
        /// only when a surface must read as floating above its content.
        static let cardShadow = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 2
        )
    }

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Motion

    /// Press feedback itself needs no token here — `.borderedProminent`,
    /// `.bordered`, and `.plain` already animate presses natively, and
    /// every button in the library rides on one of those. `Haptics`
    /// (Core/Utilities) covers tactile feedback.
    enum Motion {
        /// Default pace for a state change that shouldn't feel instant or
        /// crawl (badge/card appearance, layout shifts).
        static let standard: Double = 0.25

        /// A continuous, cyclical animation — the rest-timer progress ring.
        static let linearContinuous: Double = 1.0

        /// A surface entering/leaving alongside other content, e.g. the
        /// rest-timer badge appearing above the workout list.
        static let cardTransition: AnyTransition = .opacity.combined(with: .move(edge: .top))
    }

    // MARK: - Typography

    enum Typography {
        /// Big, glanceable numbers — rest timer, weight, reps. Rounded
        /// design feels less clinical than the system default for a
        /// fitness context. Monospaced digits keep the width stable as the
        /// value changes, so a live timer or counter doesn't jitter.
        static func numeric(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded).monospacedDigit()
        }

        /// App-level moment, e.g. the Dashboard's top-of-screen greeting.
        static let heroTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)

        /// A screen or detail view's primary heading (exercise name, card
        /// detail title) when it isn't carried by `.navigationTitle`.
        static let screenTitle = Font.system(.title2, design: .rounded).weight(.bold)

        /// Title for a card-sized unit of content.
        static let cardTitle = Font.system(.title3, design: .rounded).weight(.bold)

        static let sectionTitle = Font.system(.title3, design: .rounded).weight(.bold)
        static let label = Font.system(.subheadline, design: .rounded).weight(.semibold)
        static let caption = Font.system(.caption, design: .rounded)
        static let footnote = Font.system(.footnote, design: .rounded)
        static let eyebrow = Font.system(.caption2, design: .rounded).weight(.bold)
    }
}

extension View {
    /// Applies an `AppTheme.Elevation` shadow spec in one call.
    func appShadow(_ style: AppTheme.ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
