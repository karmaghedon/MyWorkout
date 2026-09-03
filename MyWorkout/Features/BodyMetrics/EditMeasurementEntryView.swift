import SwiftUI
import UIKit

/// Corrects the waist and/or neck/hip values already logged for one
/// calendar day. Only shows fields that entry already has a value for —
/// this isn't where you'd add a measurement that was never logged (that's
/// `LogBodyMeasurementsView`), only where you fix one that was logged
/// wrong. Waist writes go to HealthKit (delete the old sample, log the
/// corrected one, same date); neck/hip update the existing
/// `BodyMeasurementLog` in place via its `id`.
struct EditMeasurementEntryView: View {
    let entry: MeasurementDayEntry
    let showsHip: Bool
    let healthKitService: any BodyMetricsHealthKitServicing
    let bodyMeasurementLogStore: BodyMeasurementLogStore
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var waistCm: Double
    @State private var neckCm: Double
    @State private var hipCm: Double

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false

    init(
        entry: MeasurementDayEntry,
        showsHip: Bool,
        healthKitService: any BodyMetricsHealthKitServicing,
        bodyMeasurementLogStore: BodyMeasurementLogStore,
        onSaved: @escaping () -> Void
    ) {
        self.entry = entry
        self.showsHip = showsHip
        self.healthKitService = healthKitService
        self.bodyMeasurementLogStore = bodyMeasurementLogStore
        self.onSaved = onSaved

        _waistCm = State(initialValue: entry.waist?.value ?? 0)
        _neckCm = State(initialValue: entry.neckLog?.neckCm ?? 0)
        _hipCm = State(initialValue: entry.neckLog?.hipCm ?? 0)
    }

    private var hasWaist: Bool { entry.waist != nil }
    private var hasNeck: Bool { entry.neckLog?.neckCm != nil }
    private var hasHip: Bool { showsHip && entry.neckLog?.hipCm != nil }

    var body: some View {
        Form {
            if hasWaist {
                Section {
                    EditNumericField(title: "Waist", value: $waistCm, suffix: "cm")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            if hasNeck {
                Section {
                    EditNumericField(title: "Neck", value: $neckCm, suffix: "cm")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            if hasHip {
                Section {
                    EditNumericField(title: "Hip", value: $hipCm, suffix: "cm")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
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
        .navigationTitle(entry.day.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .dismissKeyboardOnTap()
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

    private func save() {
        isSaving = true

        Task {
            defer { isSaving = false }

            do {
                if hasWaist, let originalWaist = entry.waist, originalWaist.value != waistCm {
                    try await healthKitService.deleteWaistSample(date: originalWaist.date)
                    try await healthKitService.logWaist(cm: waistCm, date: originalWaist.date)
                }

                if (hasNeck || hasHip), let originalLog = entry.neckLog {
                    let newHip: Double? = hasHip ? hipCm : originalLog.hipCm

                    if originalLog.neckCm != neckCm || originalLog.hipCm != newHip {
                        await bodyMeasurementLogStore.update(
                            BodyMeasurementLog(
                                id: originalLog.id,
                                date: originalLog.date,
                                neckCm: hasNeck ? neckCm : originalLog.neckCm,
                                hipCm: newHip
                            )
                        )
                    }
                }

                onSaved()
            } catch {
                errorMessage = "Couldn't save to Health: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

/// Same directly-tappable numeric field used by `LogBodyMeasurementsView`
/// and `LogWeightView` — kept as its own private-per-screen copy per
/// this app's existing convention.
private struct EditNumericField: View {
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
