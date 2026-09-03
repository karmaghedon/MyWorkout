import SwiftUI

/// Browse, correct, or delete past weekly waist/neck/hip measurements —
/// the counterpart to `LogBodyMeasurementsView`, which can only create
/// new entries. Waist lives in HealthKit; neck and hip are local-only
/// (`BodyMeasurementLogStore`) — this screen merges both by calendar day
/// so a single row represents "what was logged for that week," and edits
/// route each field back to whichever store it actually lives in.
struct MeasurementLogHistoryView: View {
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var bodyMeasurementLogStore: BodyMeasurementLogStore

    private let healthKitService: any BodyMetricsHealthKitServicing

    /// Restricts the list to one week's worth of days when set — used
    /// when jumping here from a specific `WeeklyReportView` card via
    /// `AppRoute.measurementHistoryForWeek`, so correcting a bad week's
    /// data doesn't mean hunting for it in the full history. `nil` shows
    /// everything (the general "History" entry point).
    private let dateRange: Range<Date>?

    @State private var waistByDay: [Date: DatedValue] = [:]
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var editingEntry: MeasurementDayEntry?

    init(
        dateRange: Range<Date>? = nil,
        healthKitService: any BodyMetricsHealthKitServicing = BodyMetricsHealthKitService()
    ) {
        self.dateRange = dateRange
        self.healthKitService = healthKitService
    }

    private var entries: [MeasurementDayEntry] {
        let calendar = Calendar.current

        var byDay: [Date: MeasurementDayEntry] = [:]

        for (day, waist) in waistByDay {
            byDay[day] = MeasurementDayEntry(day: day, waist: waist, neckLog: nil)
        }

        for log in bodyMeasurementLogStore.logs {
            let day = calendar.startOfDay(for: log.date)
            byDay[day, default: MeasurementDayEntry(day: day, waist: nil, neckLog: nil)].neckLog = log
        }

        if let dateRange {
            byDay = byDay.filter { dateRange.contains($0.key) }
        }

        return byDay.values.sorted { $0.day > $1.day }
    }

    private var title: String {
        guard let dateRange else { return "Measurement History" }

        let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: dateRange.upperBound) ?? dateRange.upperBound
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return "\(formatter.string(from: dateRange.lowerBound)) – \(formatter.string(from: lastDay))"
    }

    var body: some View {
        List {
            Section {
                if isLoading && entries.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if entries.isEmpty {
                    Text(dateRange == nil ? "No measurements logged yet." : "No measurements logged for this week.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            row(for: entry)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                }
            } footer: {
                Text("Tap an entry to correct it, or swipe to delete.")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
        .refreshable { await reload() }
        .sheet(item: $editingEntry) { entry in
            NavigationStack {
                EditMeasurementEntryView(
                    entry: entry,
                    showsHip: settingsStore.settings.biologicalSex == .female,
                    healthKitService: healthKitService,
                    bodyMeasurementLogStore: bodyMeasurementLogStore,
                    onSaved: {
                        editingEntry = nil
                        Task { await reload() }
                    }
                )
            }
        }
        .alert(
            "Couldn't Load History",
            isPresented: Binding(
                get: { loadError != nil },
                set: { if !$0 { loadError = nil } }
            ),
            presenting: loadError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func row(for entry: MeasurementDayEntry) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(entry.day, style: .date)
                .font(AppTheme.Typography.cardTitle)

            Text(summary(for: entry))
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    private func summary(for entry: MeasurementDayEntry) -> String {
        var parts: [String] = []

        if let waist = entry.waist {
            parts.append("Waist \(formatWeight(waist.value)) cm")
        }
        if let neckCm = entry.neckLog?.neckCm {
            parts.append("Neck \(formatWeight(neckCm)) cm")
        }
        if let hipCm = entry.neckLog?.hipCm {
            parts.append("Hip \(formatWeight(hipCm)) cm")
        }

        return parts.isEmpty ? "No values" : parts.joined(separator: " · ")
    }

    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { entries[$0] }

        Task {
            for entry in toDelete {
                if let waist = entry.waist {
                    try? await healthKitService.deleteWaistSample(date: waist.date)
                }
                if let neckLog = entry.neckLog {
                    await bodyMeasurementLogStore.remove(id: neckLog.id)
                }
            }

            await reload()
        }
    }

    private func reload() async {
        isLoading = true

        do {
            let calendar = Calendar.current
            let waistSamples = try await healthKitService.waistSamples(since: .distantPast)

            var byDay: [Date: DatedValue] = [:]
            for sample in waistSamples {
                let day = calendar.startOfDay(for: sample.date)
                // Latest sample wins per day, matching how the rest of
                // the app resolves same-day duplicates.
                if let existing = byDay[day], existing.date > sample.date { continue }
                byDay[day] = sample
            }

            waistByDay = byDay
            loadError = nil
        } catch {
            loadError = "Couldn't load your waist history: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

/// One calendar day's merged view of waist (HealthKit) and neck/hip
/// (`BodyMeasurementLogStore`) — `waist.date` and `neckLog.date` keep
/// their own exact original timestamps so edits/deletes can target the
/// precise underlying record, even though both are grouped here under
/// the same display day.
struct MeasurementDayEntry: Identifiable {
    let day: Date
    var waist: DatedValue?
    var neckLog: BodyMeasurementLog?

    var id: Date { day }
}
