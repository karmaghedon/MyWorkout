import SwiftUI
import UIKit

/// Logs a weigh-in for `date` (defaults to today) — weight only. Body
/// fat % is never entered anywhere in this app; it's always calculated
/// (`NavyBodyFatCalculator`) from waist/neck/hip, which are logged
/// weekly on `LogBodyMeasurementsView` instead, not here.
///
/// Presented for a past date from `WeeklySummaryCard`'s tappable day
/// dots, in which case it pre-fills with that day's existing weight (if
/// any) so re-opening it edits rather than always starting blank.
struct LogWeightView: View {
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var healthKitAuthorizationManager: HealthKitAuthorizationManager
    @Environment(\.dismiss) private var dismiss

    private let healthKitService: any BodyMetricsHealthKitServicing
    private let date: Date

    @State private var weight: Double = 150

    @State private var isSaving = false
    @State private var authorizationDenied = false
    @State private var errorMessage: String?
    @State private var showError = false

    init(
        date: Date = .now,
        healthKitService: any BodyMetricsHealthKitServicing = BodyMetricsHealthKitService()
    ) {
        self.date = date
        self.healthKitService = healthKitService
    }

    var body: some View {
        Form {
            Section {
                NumericEntryField(title: "Weight", value: $weight, suffix: weightUnit)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } footer: {
                Text("Saved to Health as your weight.")
            }

            if authorizationDenied {
                Section {
                    Label(
                        "MyWorkout needs Health access to save your weight. Enable it in Settings \u{203A} Health \u{203A} Data Access & Devices \u{203A} MyWorkout.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(AppTheme.warning)
                }
            }

            Section {
                PrimaryButton(
                    title: "Save",
                    isEnabled: !isSaving,
                    isLoading: isSaving,
                    action: save
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .dismissKeyboardOnTap()
        .task {
            await requestAuthorizationIfNeeded()
            await loadExistingWeight()
        }
        .alert(
            "Couldn't Save",
            isPresented: $showError,
            presenting: errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private var navigationTitle: String {
        Calendar.current.isDateInToday(date)
            ? "Log Weight"
            : "Log Weight \u{2014} \(date.formatted(date: .abbreviated, time: .omitted))"
    }

    // MARK: - Units

    private var weightUnit: String {
        settingsStore.settings.bodyWeightUnitSystem.rawValue
    }

    private var weightKilograms: Double {
        let pounds = WeightConversion.toPounds(
            weight,
            from: settingsStore.settings.bodyWeightUnitSystem
        )

        return WeightConversion.poundsToKilograms(pounds)
    }

    private func displayWeight(kg: Double) -> Double {
        let pounds = WeightConversion.kilogramsToPounds(kg)
        return WeightConversion.fromPounds(pounds, to: settingsStore.settings.bodyWeightUnitSystem)
    }

    // MARK: - Authorization

    private func requestAuthorizationIfNeeded() async {
        guard healthKitAuthorizationManager.isHealthDataAvailable else { return }

        do {
            try await healthKitAuthorizationManager.requestAuthorization()
            authorizationDenied = false
        } catch {
            authorizationDenied = true
        }
    }

    // MARK: - Load existing

    private func loadExistingWeight() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        do {
            let samples = try await healthKitService.weightSamples(since: startOfDay)

            if let latestThatDay = samples
                .filter({ calendar.isDate($0.date, inSameDayAs: date) })
                .max(by: { $0.date < $1.date }) {
                weight = displayWeight(kg: latestThatDay.value)
            }
        } catch {
            // Not worth surfacing an error just for a pre-fill attempt.
        }
    }

    // MARK: - Save

    private func save() {
        isSaving = true

        Task {
            defer { isSaving = false }

            do {
                try await healthKitService.logWeight(
                    kg: weightKilograms,
                    date: date
                )

                dismiss()
            } catch {
                errorMessage = "Couldn't save to Health: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

/// A directly-tappable numeric field (brings up the number pad
/// immediately, no +/- buttons) — same "replace the whole number" input
/// model as the workout session's Checklist next-set fields, and reusing
/// the same `NumericPadTextField` (cursor pinned to the end regardless of
/// tap position, so typing always appends/deletes rather than landing
/// mid-string). Kept private to this screen rather than merged into
/// `DoubleBigStepperControl`/`BigStepperControl` — both of those are
/// shared with the workout session screens, where the +/- buttons are a
/// deliberate, already-tuned part of that UI; body-metrics entry doesn't
/// need them.
private struct NumericEntryField: View {
    let title: String
    @Binding var value: Double
    let suffix: String?

    @State private var text = ""

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                NumericPadTextField(
                    text: $text,
                    keyboardType: .decimalPad,
                    textAlignment: .center,
                    font: numericFont
                )
                .frame(height: 40)

                if let suffix {
                    Text(suffix)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .onChange(of: text) {
            updateValueWhileTyping()
        }
        .onChange(of: value) {
            syncTextFromValue()
        }
        .onAppear {
            syncTextFromValue()
        }
    }

    private func updateValueWhileTyping() {
        guard !text.isEmpty else { return }

        if let parsed = Double(text.replacingOccurrences(of: ",", with: ".")) {
            value = parsed
        }
    }

    private func syncTextFromValue() {
        text = formatWeight(value)
    }

    private var numericFont: UIFont {
        let base = UIFont.systemFont(ofSize: 30, weight: .bold)
        guard let roundedDescriptor = base.fontDescriptor.withDesign(.rounded) else {
            return base
        }
        return UIFont(descriptor: roundedDescriptor, size: 30)
    }
}
