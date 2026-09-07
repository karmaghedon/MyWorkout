import SwiftUI
import UIKit

/// Logs this week's waist and neck (and hip, for the women's Navy
/// formula) — a weekly screen, separate from `LogWeightView`'s daily
/// weight entry. Waist goes to HealthKit; neck and hip have no
/// HealthKit quantity type, so they're local-only
/// (`BodyMeasurementLogStore`), same as before. There's no toggle
/// gating here the way `LogWeightView` once had — this screen exists
/// specifically for these measurements, so both fields are always
/// shown (hip only when Biological Sex is set to Female in Settings).
struct LogBodyMeasurementsView: View {
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var healthKitAuthorizationManager: HealthKitAuthorizationManager
    @EnvironmentObject private var bodyMeasurementLogStore: BodyMeasurementLogStore
    @Environment(\.dismiss) private var dismiss

    private let healthKitService: any BodyMetricsHealthKitServicing

    @State private var waistCm: Double = 80
    @State private var neckCm: Double = 38
    @State private var hipCm: Double = 95

    @State private var isSaving = false
    @State private var authorizationDenied = false
    @State private var errorMessage: String?
    @State private var showError = false

    init(
        healthKitService: any BodyMetricsHealthKitServicing = BodyMetricsHealthKitService()
    ) {
        self.healthKitService = healthKitService
    }

    var body: some View {
        Form {
            Section {
                NumericEntryField(title: "Waist", value: $waistCm, suffix: "cm")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } footer: {
                Text("Saved to Health as your waist circumference.")
            }

            Section {
                NumericEntryField(title: "Neck", value: $neckCm, suffix: "cm")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } footer: {
                Text("Neck isn't tracked by Health, so it's saved in MyWorkout only.")
            }

            if settingsStore.settings.biologicalSex == .female {
                Section {
                    NumericEntryField(title: "Hip", value: $hipCm, suffix: "cm")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } footer: {
                    Text("Needed for the body fat % estimate. Saved in MyWorkout only, same as neck.")
                }
            }

            if authorizationDenied {
                Section {
                    Label(
                        "MyWorkout needs Health access to save your waist measurement. Enable it in Settings \u{203A} Health \u{203A} Data Access & Devices \u{203A} MyWorkout.",
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
        .navigationTitle("Weekly Measurements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.measurementHistory) {
                    Text("History")
                }
            }
        }
        .dismissKeyboardOnTap()
        .task {
            await requestAuthorizationIfNeeded()
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

    // MARK: - Save

    private func save() {
        isSaving = true

        Task {
            defer { isSaving = false }

            do {
                try await healthKitService.logWaist(
                    cm: waistCm,
                    date: .now
                )

                bodyMeasurementLogStore.add(
                    BodyMeasurementLog(
                        date: .now,
                        neckCm: neckCm,
                        hipCm: settingsStore.settings.biologicalSex == .female ? hipCm : nil
                    )
                )

                dismiss()
            } catch {
                errorMessage = "Couldn't save to Health: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

/// Same directly-tappable numeric field as `LogWeightView`'s — kept as
/// its own private copy rather than shared, matching this app's
/// existing convention of one small screen-private numeric field per
/// body-metrics screen (see `LogWeightView`'s identical type for the
/// full rationale).
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
