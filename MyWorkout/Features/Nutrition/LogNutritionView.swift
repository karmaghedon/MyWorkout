import SwiftUI
import UIKit

/// Sets `date`'s (defaults to today) total macros. This is a
/// calorie/macro tracker, not a food diary: there is one editable
/// record per calendar day (`DailyNutritionLogStore.upsert`), not a
/// list of individual food items. Calories are always derived from
/// macros via the standard 4/4/9 kcal-per-gram rule and shown
/// read-only — never entered directly.
///
/// Presented for a past date from `WeeklySummaryCard`'s tappable day
/// dots, in which case it pre-fills with that day's existing entry (if
/// any) so re-opening it edits rather than always starting blank.
struct LogNutritionView: View {
    @EnvironmentObject private var dailyNutritionLogStore: DailyNutritionLogStore
    @EnvironmentObject private var healthKitAuthorizationManager: HealthKitAuthorizationManager

    private let healthKitService: any NutritionHealthKitServicing
    private let date: Date

    @State private var proteinG = 0
    @State private var carbsG = 0
    @State private var fatG = 0

    @State private var isSaving = false
    @State private var authorizationDenied = false
    @State private var errorMessage: String?
    @State private var showError = false

    init(
        date: Date = .now,
        healthKitService: any NutritionHealthKitServicing = NutritionHealthKitService()
    ) {
        self.date = date
        self.healthKitService = healthKitService
    }

    var body: some View {
        List {
            Section {
                caloriesSummary
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                NumericEntryField(title: "Protein", value: $proteinG, suffix: "g")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                NumericEntryField(title: "Carbs", value: $carbsG, suffix: "g")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                NumericEntryField(title: "Fat", value: $fatG, suffix: "g")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                PrimaryButton(
                    title: "Save Totals",
                    isEnabled: !isSaving,
                    isLoading: isSaving,
                    action: save
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } footer: {
                Text("Calories are calculated automatically from your macros.")
            }

            if authorizationDenied {
                Section {
                    Label(
                        "MyWorkout needs Health access to save your nutrition log. Enable it in Settings \u{203A} Health \u{203A} Data Access & Devices \u{203A} MyWorkout.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(AppTheme.warning)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .dismissKeyboardOnTap()
        .task {
            await requestAuthorizationIfNeeded()
            loadExistingEntry()
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
            ? "Today's Nutrition"
            : "Nutrition \u{2014} \(date.formatted(date: .abbreviated, time: .omitted))"
    }

    private var caloriesSummary: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("\(computedCalories)")
                .font(AppTheme.Typography.numeric(40))

            Text("calories")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
    }

    private var computedCalories: Int {
        proteinG * 4 + carbsG * 4 + fatG * 9
    }

    private func loadExistingEntry() {
        guard let entry = dailyNutritionLogStore.entry(on: date) else { return }

        proteinG = entry.proteinG
        carbsG = entry.carbsG
        fatG = entry.fatG
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
                try await healthKitService.logDailyTotals(
                    proteinG: Double(proteinG),
                    carbsG: Double(carbsG),
                    fatG: Double(fatG),
                    calories: Double(computedCalories),
                    date: date
                )

                dailyNutritionLogStore.upsert(
                    date: date,
                    proteinG: proteinG,
                    carbsG: carbsG,
                    fatG: fatG
                )
            } catch {
                errorMessage = "Couldn't save to Health: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

/// A directly-tappable numeric field (brings up the number pad
/// immediately, no +/- buttons) — mirrors `LogWeightView`'s
/// `NumericEntryField` but for whole-number macros rather than a
/// decimal weight. Kept private to this screen rather than merged into
/// `BigStepperControl`: that component is shared with the workout
/// session screens, where +/- buttons are a deliberate, already-tuned
/// part of that UI; macro entry doesn't want them (reported as such
/// after the first on-device pass, same reasoning that led to
/// `LogWeightView`'s own numpad-only fields).
private struct NumericEntryField: View {
    let title: String
    @Binding var value: Int
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
                    keyboardType: .numberPad,
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

        if let parsed = Int(text) {
            value = parsed
        }
    }

    private func syncTextFromValue() {
        text = "\(value)"
    }

    private var numericFont: UIFont {
        let base = UIFont.systemFont(ofSize: 30, weight: .bold)
        guard let roundedDescriptor = base.fontDescriptor.withDesign(.rounded) else {
            return base
        }
        return UIFont(descriptor: roundedDescriptor, size: 30)
    }
}
