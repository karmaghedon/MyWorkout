import SwiftUI
import Charts

/// A single chart with weight, waist, and neck all plotted as separate
/// color-coded lines on one shared axis, toggled on/off independently.
/// Unlike `WeeklyReportView`'s aggregated weekly cards, this plots
/// every individual sample.
///
/// Weight (lb/kg) and waist/neck (cm) are different units sharing one
/// numeric axis — a real tradeoff, since Swift Charts has no simple
/// secondary-axis support — but a single combined chart with a
/// color-coded legend is the requested view: one graph, multiple
/// lines, rather than separate panels per metric.
struct BodyProgressView: View {
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var bodyMeasurementLogStore: BodyMeasurementLogStore

    private let healthKitService: any BodyMetricsHealthKitServicing

    @State private var selectedRange: DateRangeOption = .threeMonths
    @State private var showWaist = false
    @State private var showNeck = false

    @State private var weightSamples: [DatedValue] = []
    @State private var waistSamples: [DatedValue] = []
    @State private var isLoading = false
    @State private var loadError: String?

    init(
        healthKitService: any BodyMetricsHealthKitServicing = BodyMetricsHealthKitService()
    ) {
        self.healthKitService = healthKitService
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                DateRangePicker(selection: $selectedRange)
                    .padding(.horizontal)

                overlayToggles
                    .padding(.horizontal)

                content
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Weight & Body")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await reload()
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && weightPoints.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.Spacing.xl)
        } else if let loadError {
            Text(loadError)
                .foregroundStyle(AppTheme.warning)
        } else if weightPoints.isEmpty {
            AppEmptyStateView(
                title: "No Weigh-Ins Yet",
                message: "Log a weigh-in to see your progress chart.",
                systemImage: "chart.line.uptrend.xyaxis"
            )
        } else {
            combinedChart
        }
    }

    private var overlayToggles: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Toggle("Waist", isOn: $showWaist)
                .toggleStyle(.button)

            Toggle("Neck", isOn: $showNeck)
                .toggleStyle(.button)

            Spacer()
        }
    }

    private var combinedChart: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Weight (\(settingsStore.settings.bodyWeightUnitSystem.rawValue)) · Waist/Neck (cm)")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.secondaryText)

            Chart {
                ForEach(weightPoints, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(by: .value("Metric", "Weight"))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(by: .value("Metric", "Weight"))
                }

                if showWaist {
                    ForEach(waistPoints, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(by: .value("Metric", "Waist"))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(by: .value("Metric", "Waist"))
                    }
                }

                if showNeck {
                    ForEach(neckPoints, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(by: .value("Metric", "Neck"))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(by: .value("Metric", "Neck"))
                    }
                }
            }
            .frame(height: 280)
        }
    }

    // MARK: - Data

    private var weightPoints: [DatedValue] {
        filtered(weightSamples).map {
            DatedValue(date: $0.date, value: displayWeight(kg: $0.value))
        }
    }

    private var waistPoints: [DatedValue] {
        filtered(waistSamples)
    }

    private var neckPoints: [DatedValue] {
        let neckSamples = bodyMeasurementLogStore.logs.compactMap { log -> DatedValue? in
            guard let neckCm = log.neckCm else { return nil }
            return DatedValue(date: log.date, value: neckCm)
        }

        return filtered(neckSamples)
    }

    private func filtered(_ samples: [DatedValue]) -> [DatedValue] {
        let sorted = samples.sorted { $0.date < $1.date }

        guard let startDate = selectedRange.startDate() else {
            return sorted
        }

        return sorted.filter { $0.date >= startDate }
    }

    private func displayWeight(kg: Double) -> Double {
        let pounds = WeightConversion.kilogramsToPounds(kg)
        return WeightConversion.fromPounds(pounds, to: settingsStore.settings.bodyWeightUnitSystem)
    }

    // MARK: - Loading

    private func reload() async {
        isLoading = true

        do {
            weightSamples = try await healthKitService.weightSamples(since: .distantPast)
            waistSamples = try await healthKitService.waistSamples(since: .distantPast)
            loadError = nil
        } catch {
            loadError = "Couldn't load your progress chart: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
