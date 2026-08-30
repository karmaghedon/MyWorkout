import SwiftUI

/// How far back a chart should look. No existing date-range component
/// in this app to match — this is the first one, kept generic so any
/// future chart screen can reuse it rather than each inventing its own.
enum DateRangeOption: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "All"

    var id: String { rawValue }

    /// The earliest date to include, or `nil` for `.all` (no lower bound
    /// — every sample is included regardless of age).
    func startDate(from now: Date = .now) -> Date? {
        let calendar = Calendar.current

        switch self {
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: now)
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now)
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now)
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .all:
            return nil
        }
    }
}

struct DateRangePicker: View {
    @Binding var selection: DateRangeOption

    var body: some View {
        Picker("Date Range", selection: $selection) {
            ForEach(DateRangeOption.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}
