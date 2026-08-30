import SwiftUI
import Charts

/// A combined, multi-metric progress chart — weight (dots + smoothed
/// trend line), body fat %, waist, neck, calories, and steps, all
/// toggle-selectable and plotted together on one chart. Each active
/// metric's values are independently min-max normalized before
/// plotting (`normalize(...)`) rather than sharing one literal numeric
/// axis: weight (lb/kg), body fat % (0-100), circumferences (cm),
/// calories (kcal), and steps (count) have wildly different scales, so
/// a shared literal axis would flatten most of them into invisible
/// near-zero lines. The y-axis is hidden entirely since normalized
/// values have no independent meaning — real values are surfaced via
/// the summary tiles (delta/average per metric over the selected
/// window) and the tap-to-inspect tooltip.
///
/// The date range supports paging backward/forward through history
/// (`DateRangeOption.steppedBackward/steppedForward`), not just "last N
/// months from today" — `windowEnd` is the anchor, defaulting to now.
struct BodyProgressView: View {
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var bodyMeasurementLogStore: BodyMeasurementLogStore
    @EnvironmentObject private var dailyNutritionLogStore: DailyNutritionLogStore

    private let healthKitService: any BodyMetricsHealthKitServicing
    private let activityHealthKitService: any ActivityHealthKitServicing

    @State private var selectedRange: DateRangeOption = .threeMonths
    @State private var windowEnd: Date = .now
    @State private var selectedMetrics: Set<ProgressMetric> = [.weight]

    @State private var weightSamples: [DatedValue] = []
    @State private var waistSamples: [DatedValue] = []
    @State private var bodyFatPercentSamples: [DatedValue] = []
    @State private var stepSamples: [DatedValue] = []

    @State private var isLoading = false
    @State private var loadError: String?

    @State private var tappedDate: Date?

    init(
        healthKitService: any BodyMetricsHealthKitServicing = BodyMetricsHealthKitService(),
        activityHealthKitService: any ActivityHealthKitServicing = ActivityHealthKitService()
    ) {
        self.healthKitService = healthKitService
        self.activityHealthKitService = activityHealthKitService
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                metricChips

                content

                VStack(spacing: AppTheme.Spacing.sm) {
                    DateRangePicker(selection: $selectedRange)
                        .onChange(of: selectedRange) { _, _ in windowEnd = .now }

                    rangeNavigator
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
        .navigationTitle("Weight & Body")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await reload()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if isLoading && weightSamples.isEmpty && waistSamples.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.Spacing.xl)
        } else if let loadError {
            Text(loadError)
                .foregroundStyle(AppTheme.warning)
        } else if selectedMetrics.isEmpty {
            Text("Select at least one metric above to see a chart.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.Spacing.xl)
        } else if selectedMetrics.allSatisfy({ points(for: $0).isEmpty }) {
            AppEmptyStateView(
                title: "No Data Yet",
                message: "Log a weigh-in to see your progress chart.",
                systemImage: "chart.line.uptrend.xyaxis"
            )
        } else {
            summaryTiles
            combinedChart
            tooltip
        }
    }

    // MARK: - Metric chips

    private var metricChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(ProgressMetric.allCases) { metric in
                    metricChip(metric)
                }
            }
        }
    }

    private func metricChip(_ metric: ProgressMetric) -> some View {
        let isSelected = selectedMetrics.contains(metric)

        return Button {
            toggle(metric)
        } label: {
            Text(metric.displayName)
                .font(AppTheme.Typography.caption)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Capsule().fill(isSelected ? metric.color : AppTheme.cardBackground))
                .foregroundStyle(isSelected ? Color.white : AppTheme.secondaryText)
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ metric: ProgressMetric) {
        if selectedMetrics.contains(metric) {
            selectedMetrics.remove(metric)
        } else {
            selectedMetrics.insert(metric)
        }
        tappedDate = nil
    }

    // MARK: - Summary tiles

    private var summaryTiles: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(ProgressMetric.allCases.filter { selectedMetrics.contains($0) }) { metric in
                    summaryTile(for: metric)
                }
            }
        }
    }

    private func summaryTile(for metric: ProgressMetric) -> some View {
        let raw = points(for: metric).sorted { $0.date < $1.date }

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(metric.displayName)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.secondaryText)

            if metric.isDailyAggregate {
                if !raw.isEmpty {
                    let average = raw.map(\.value).reduce(0, +) / Double(raw.count)
                    Text("avg \(formattedValue(average, for: metric))")
                        .font(AppTheme.Typography.label)
                } else {
                    Text("No data")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            } else if let first = raw.first?.value, let last = raw.last?.value {
                let delta = last - first
                Text("\(deltaGlyph(delta)) \(formattedValue(abs(delta), for: metric))")
                    .font(AppTheme.Typography.label)
            } else {
                Text("No data")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private func deltaGlyph(_ delta: Double) -> String {
        if delta > 0 { "▲" } else if delta < 0 { "▼" } else { "–" }
    }

    // MARK: - Chart

    private var combinedChart: some View {
        Chart {
            ForEach(ProgressMetric.allCases.filter { selectedMetrics.contains($0) }) { metric in
                chartContent(for: metric)
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 260)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                updateTappedDate(at: drag.location, proxy: proxy, geometry: geometry)
                            }
                    )
            }
        }
    }

    @ChartContentBuilder
    private func chartContent(for metric: ProgressMetric) -> some ChartContent {
        let raw = points(for: metric)
        let values = raw.map(\.value)

        if let minValue = values.min(), let maxValue = values.max() {
            ForEach(normalize(raw, referenceMin: minValue, referenceMax: maxValue), id: \.date) { point in
                if metric == .weight {
                    PointMark(x: .value("Date", point.date), y: .value("Value", point.value))
                        .foregroundStyle(metric.color)
                } else {
                    LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                        .foregroundStyle(metric.color)
                }
            }

            if metric == .weight {
                let trend = normalize(
                    TrendSmoother.movingAverage(raw),
                    referenceMin: minValue,
                    referenceMax: maxValue
                )

                ForEach(trend, id: \.date) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private func normalize(_ points: [DatedValue], referenceMin: Double, referenceMax: Double) -> [DatedValue] {
        guard referenceMax > referenceMin else {
            return points.map { DatedValue(date: $0.date, value: 50) }
        }

        return points.map {
            DatedValue(date: $0.date, value: ($0.value - referenceMin) / (referenceMax - referenceMin) * 100)
        }
    }

    // MARK: - Tap to inspect

    private func updateTappedDate(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let origin = geometry[proxy.plotAreaFrame].origin
        let relativeX = location.x - origin.x

        guard let date: Date = proxy.value(atX: relativeX) else { return }

        tappedDate = date
    }

    @ViewBuilder
    private var tooltip: some View {
        if let tappedDate {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(tappedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTheme.Typography.label)

                ForEach(ProgressMetric.allCases.filter { selectedMetrics.contains($0) }) { metric in
                    if let value = nearestValue(for: metric, to: tappedDate) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Circle().fill(metric.color).frame(width: 8, height: 8)
                            Text(metric.displayName)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Text(formattedValue(value, for: metric))
                        }
                        .font(AppTheme.Typography.caption)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
        }
    }

    private func nearestValue(for metric: ProgressMetric, to date: Date, toleranceDays: Double = 3) -> Double? {
        let candidates = points(for: metric)

        guard let nearest = candidates.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        }) else {
            return nil
        }

        let daysDifference = abs(nearest.date.timeIntervalSince(date)) / 86_400
        guard daysDifference <= toleranceDays else { return nil }

        return nearest.value
    }

    // MARK: - Range navigation

    private var rangeNavigator: some View {
        HStack {
            Button {
                stepBackward()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(selectedRange == .all)

            Spacer()

            Text(rangeText)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()

            Button {
                stepForward()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(selectedRange == .all || isAtPresent)
        }
    }

    private var isAtPresent: Bool {
        Calendar.current.isDate(windowEnd, inSameDayAs: .now)
    }

    private func stepBackward() {
        guard let newEnd = selectedRange.steppedBackward(from: windowEnd) else { return }
        windowEnd = newEnd
        tappedDate = nil
    }

    private func stepForward() {
        guard let newEnd = selectedRange.steppedForward(from: windowEnd) else { return }
        windowEnd = min(newEnd, .now)
        tappedDate = nil
    }

    private var rangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"

        guard let start = selectedRange.startDate(from: windowEnd) else {
            return "All time"
        }

        return "\(formatter.string(from: start)) \u{2013} \(formatter.string(from: windowEnd))"
    }

    // MARK: - Data

    private func rawPoints(for metric: ProgressMetric) -> [DatedValue] {
        switch metric {
        case .weight:
            return weightSamples.map { DatedValue(date: $0.date, value: displayWeight(kg: $0.value)) }

        case .bodyFatPercent:
            return bodyFatPercentSamples

        case .waist:
            return waistSamples

        case .neck:
            return bodyMeasurementLogStore.logs.compactMap { log -> DatedValue? in
                guard let neckCm = log.neckCm else { return nil }
                return DatedValue(date: log.date, value: neckCm)
            }

        case .calories:
            return dailyNutritionLogStore.logs.map { DatedValue(date: $0.date, value: Double($0.calories)) }

        case .steps:
            return stepSamples
        }
    }

    private func points(for metric: ProgressMetric) -> [DatedValue] {
        let sorted = rawPoints(for: metric).sorted { $0.date < $1.date }

        guard let start = selectedRange.startDate(from: windowEnd) else {
            return sorted.filter { $0.date <= windowEnd }
        }

        return sorted.filter { $0.date >= start && $0.date <= windowEnd }
    }

    private func displayWeight(kg: Double) -> Double {
        let pounds = WeightConversion.kilogramsToPounds(kg)
        return WeightConversion.fromPounds(pounds, to: settingsStore.settings.bodyWeightUnitSystem)
    }

    private func formattedValue(_ value: Double, for metric: ProgressMetric) -> String {
        switch metric {
        case .weight:
            return "\(formatWeight(value)) \(settingsStore.settings.bodyWeightUnitSystem.rawValue)"
        case .bodyFatPercent:
            return "\(formatWeight(value)) %"
        case .waist, .neck:
            return "\(formatWeight(value)) cm"
        case .calories:
            return "\(Int(value)) kcal"
        case .steps:
            return "\(Int(value)) steps"
        }
    }

    // MARK: - Loading

    private func reload() async {
        isLoading = true

        do {
            weightSamples = try await healthKitService.weightSamples(since: .distantPast)
            waistSamples = try await healthKitService.waistSamples(since: .distantPast)
            let actualBodyFatPercent = try await healthKitService.bodyFatPercentSamples(since: .distantPast)

            // Bounded, unlike the sample-query fetches above: a
            // day-bucketed HKStatisticsCollectionQuery enumerates every
            // day in its range even when empty, so `.distantPast` here
            // would mean iterating millennia of empty buckets.
            let stepsLookback = Calendar.current.date(byAdding: .year, value: -5, to: .now) ?? .now
            stepSamples = try await activityHealthKitService.dailyStepTotals(since: stepsLookback)

            let neck = bodyMeasurementLogStore.logs.compactMap { log -> DatedValue? in
                guard let neckCm = log.neckCm else { return nil }
                return DatedValue(date: log.date, value: neckCm)
            }
            let hip = bodyMeasurementLogStore.logs.compactMap { log -> DatedValue? in
                guard let hipCm = log.hipCm else { return nil }
                return DatedValue(date: log.date, value: hipCm)
            }

            bodyFatPercentSamples = NavyBodyFatCalculator.fillGaps(
                actual: actualBodyFatPercent,
                waist: waistSamples,
                neck: neck,
                hip: hip,
                sex: settingsStore.settings.biologicalSex,
                heightCm: settingsStore.settings.heightCm
            )

            loadError = nil
        } catch {
            loadError = "Couldn't load your progress chart: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

/// A toggle-selectable chart series. Kept private to this screen —
/// nothing else needs a "which body/activity metric" enum.
private enum ProgressMetric: String, CaseIterable, Identifiable {
    case weight
    case bodyFatPercent
    case waist
    case neck
    case calories
    case steps

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weight: "Weight"
        case .bodyFatPercent: "Fat %"
        case .waist: "Waist"
        case .neck: "Neck"
        case .calories: "Calories"
        case .steps: "Steps"
        }
    }

    var color: Color {
        switch self {
        case .weight: AppTheme.accent
        case .bodyFatPercent: .cyan
        case .waist: .orange
        case .neck: .purple
        case .calories: .green
        case .steps: .pink
        }
    }

    /// Whether this metric is a running daily total (steps, calories)
    /// rather than a point-in-time reading (weight, fat %, waist,
    /// neck) — governs whether its summary tile shows a period average
    /// instead of a first-vs-last delta.
    var isDailyAggregate: Bool {
        self == .calories || self == .steps
    }
}
