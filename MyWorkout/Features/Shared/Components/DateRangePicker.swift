import SwiftUI

/// How far back a chart should look, and how far a "window" of that
/// length can be paged backward/forward through history. No existing
/// date-range component in this app to match — this is the first one,
/// kept generic so any future chart screen can reuse it.
enum DateRangeOption: String, CaseIterable, Identifiable {
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "All"

    var id: String { rawValue }

    /// `nil` for `.all` — there is no fixed length to step by, so
    /// paging is disabled for it.
    private var stepUnit: (component: Calendar.Component, value: Int)? {
        switch self {
        case .oneWeek: (.day, 7)
        case .oneMonth: (.month, 1)
        case .threeMonths: (.month, 3)
        case .sixMonths: (.month, 6)
        case .oneYear: (.year, 1)
        case .all: nil
        }
    }

    /// The earliest date to include in a window ending at `date`, or
    /// `nil` for `.all` (no lower bound — every sample up to `date` is
    /// included).
    func startDate(from date: Date = .now) -> Date? {
        guard let stepUnit else { return nil }
        return Calendar.current.date(byAdding: stepUnit.component, value: -stepUnit.value, to: date)
    }

    /// Moves `anchor` back by exactly one window length — paging to the
    /// previous period. `nil` for `.all`.
    func steppedBackward(from anchor: Date) -> Date? {
        guard let stepUnit else { return nil }
        return Calendar.current.date(byAdding: stepUnit.component, value: -stepUnit.value, to: anchor)
    }

    /// Moves `anchor` forward by exactly one window length — paging to
    /// the next period. Callers should clamp the result to not exceed
    /// `.now`, since paging into the future has nothing to show.
    /// `nil` for `.all`.
    func steppedForward(from anchor: Date) -> Date? {
        guard let stepUnit else { return nil }
        return Calendar.current.date(byAdding: stepUnit.component, value: stepUnit.value, to: anchor)
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
