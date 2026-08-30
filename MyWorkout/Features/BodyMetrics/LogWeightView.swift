import SwiftUI
import UIKit

/// Logs a weigh-in. Weight is required and always goes to HealthKit;
/// body fat % and waist are optional HealthKit fields; neck (everyone)
/// and hip (shown only when Biological Sex is set to Female in
/// Settings, since it's only needed for the women's Navy body-fat
/// formula) are optional and local-only (`BodyMeasurementLogStore`)
/// since HealthKit has no quantity type for either.
struct LogWeightView: View {
    @EnvironmentObject private var settingsStore: UserSettingsStore
    @EnvironmentObject private var healthKitAuthorizationManager: HealthKitAuthorizationManager
    @EnvironmentObject private var bodyMeasurementLogStore: BodyMeasurementLogStore
    @Environment(\.dismiss) private var dismiss

    private let healthKitService: any BodyMetricsHealthKitServicing

    @State private var weight: Double = 150
    @State private var bodyFatPercent: Double = 20
    @State private var waistCm: Double = 80
    @State private var neckCm: Double = 38
    @State private var hipCm: Double = 95

    @State private var includeBodyFat = false
    @State private var includeWaist = false
    @State private var includeNeck = false
    @State private var includeHip = false

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
                NumericEntryField(title: "Weight", value: $weight, suffix: weightUnit)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } footer: {
                Text("Saved to Health as your weight.")
            }

            Section {
                Toggle("Body Fat %", isOn: $includeBodyFat.animation())

                if includeBodyFat {
                    NumericEntryField(title: "Body Fat", value: $bodyFatPercent, suffix: "%")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                Toggle("Waist", isOn: $includeWaist.animation())

                if includeWaist {
                    NumericEntryField(title: "Waist", value: $waistCm, suffix: "cm")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                Toggle("Neck", isOn: $includeNeck.animation())

                if includeNeck {
                    NumericEntryField(title: "Neck", value: $neckCm, suffix: "cm")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            } footer: {
                Text("Neck isn't tracked by Health, so it's saved in MyWorkout only.")
            }

            if settingsStore.settings.biologicalSex == .female {
                Section {
                    Toggle("Hip", isOn: $includeHip.animation())

                    if includeHip {
                        NumericEntryField(title: "Hip", value: $hipCm, suffix: "cm")
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                } footer: {
                    Text("Needed for the body fat % estimate on days without a direct reading. Saved in MyWorkout only, same as neck.")
                }
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
        .navigationTitle("Log Weight")
        .navigationBarTitleDisplayMode(.inline)
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
                try await healthKitService.logWeight(
                    kg: weightKilograms,
                    bodyFatPercent: includeBodyFat ? bodyFatPercent : nil,
                    waistCm: includeWaist ? waistCm : nil,
                    date: .now
                )

                if includeNeck || includeHip {
                    bodyMeasurementLogStore.add(
                        BodyMeasurementLog(
                            date: .now,
                            neckCm: includeNeck ? neckCm : nil,
                            hipCm: includeHip ? hipCm : nil
                        )
                    )
                }

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
