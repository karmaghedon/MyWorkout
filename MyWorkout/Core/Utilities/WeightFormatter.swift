import Foundation

/// Formats a weight value for display - shows decimals only when fractional
func formatWeight(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", value)
        : String(format: "%.1f", value)
}
