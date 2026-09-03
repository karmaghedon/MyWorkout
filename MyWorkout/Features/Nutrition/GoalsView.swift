import SwiftUI
import UIKit

/// Sets and reviews calorie/macro targets. A goal takes effect on a chosen
/// date, and `MacroGoalStore.activeGoal(on:)` resolves which one applies to
/// any given day — this screen is where that history is built and browsed,
/// not where "today's" resolved goal is shown (that's the Home nutrition
/// card, added in a later phase).
///
/// A macro goal is something you set occasionally, not daily — so the form
/// pre-fills from whatever goal is active today rather than always
/// resetting to hardcoded defaults, which otherwise made it look like the
/// last goal you set had been lost every time you reopened this screen.
///
/// Calories is always a manual, independent field — never derived from the
/// macros. Grams are the actual source of truth (`MacroGoal` only stores
/// grams); percentage is a computed, editable view of those same grams
/// relative to calories, using the standard 4 kcal/g (protein, carbs) and
/// 9 kcal/g (fat) conversion factors. Switching the mode toggle doesn't
/// change any stored value, only how you're currently entering it.
struct GoalsView: View {
    @EnvironmentObject private var macroGoalStore: MacroGoalStore

    @State private var effectiveDate = Date.now
    @State private var calories = 2_000
    @State private var proteinG = 150
    @State private var carbsG = 200
    @State private var fatG = 65
    @State private var entryMode: MacroEntryMode = .grams

    /// Macros in the order they were last directly edited (by you typing
    /// into that field, in either grams or percent — not by being
    /// auto-adjusted as someone else's flex partner), oldest first. Drives
    /// which macro absorbs the next edit's redistribution: see
    /// `applyDirectEdit(_:percent:)`.
    @State private var editOrder: [Macro] = []

    var body: some View {
        List {
            Section {
                DatePicker(
                    "Effective Date",
                    selection: $effectiveDate,
                    displayedComponents: .date
                )

                IntEntryField(title: "Calories", value: $calories, suffix: "kcal")
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                entryModeToggle
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                macroField(.protein)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                macroField(.carbs)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                macroField(.fat)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                PrimaryButton(title: "Save Goal", action: saveGoal)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } header: {
                Text("New Goal")
            }

            Section {
                if macroGoalStore.goals.isEmpty {
                    Text("No goals set yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(macroGoalStore.goals) { goal in
                        goalRow(goal)
                    }
                    .onDelete(perform: macroGoalStore.delete)
                }
            } header: {
                Text("History")
            }
        }
        .navigationTitle("Macro Goals")
        .navigationBarTitleDisplayMode(.inline)
        .dismissKeyboardOnTap()
        .onAppear {
            prefillFromActiveGoal()
        }
    }

    // MARK: - Entry Mode Toggle

    /// A plain `Button`-based segmented look, not `Picker(.segmented)` —
    /// that picker style has a known gesture conflict with `List`'s own
    /// row-tap recognizer that made it need a long press to register.
    /// Plain buttons already respond to a normal single tap everywhere
    /// else in this same list (see `PrimaryButton`).
    private var entryModeToggle: some View {
        HStack(spacing: 4) {
            ForEach(MacroEntryMode.allCases) { mode in
                Button {
                    entryMode = mode
                } label: {
                    Text(mode.label)
                        .font(AppTheme.Typography.label)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .foregroundStyle(entryMode == mode ? Color.white : AppTheme.secondaryText)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                                .fill(entryMode == mode ? AppTheme.accent : AppTheme.cardBackground)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Macro Field

    @ViewBuilder
    private func macroField(_ macro: Macro) -> some View {
        switch entryMode {
        case .grams:
            VStack(spacing: AppTheme.Spacing.xs) {
                IntEntryField(title: macro.label, value: gramsBinding(macro), suffix: "g")
                caption(percentOfCalories(macro).map { "\u{2248} \($0)% of calories" })
            }

        case .percent:
            VStack(spacing: AppTheme.Spacing.xs) {
                IntEntryField(title: macro.label, value: percentBinding(macro), suffix: "%")
                caption("\u{2248} \(grams(macro)) g")
            }
        }
    }

    @ViewBuilder
    private func caption(_ text: String?) -> some View {
        if let text {
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Macro Values

    private func grams(_ macro: Macro) -> Int {
        switch macro {
        case .protein: return proteinG
        case .carbs: return carbsG
        case .fat: return fatG
        }
    }

    private func setGrams(_ value: Int, _ macro: Macro) {
        switch macro {
        case .protein: proteinG = value
        case .carbs: carbsG = value
        case .fat: fatG = value
        }
    }

    /// Grams typed here are kept *exactly* as typed for this macro —
    /// never rounded through a grams→percent→grams round trip, which
    /// previously corrupted the field while you were still typing (a
    /// small number like "4" rounds down to 0% of calories, and
    /// converting that 0% back to grams snapped the field to 0 before
    /// you could finish typing). Only the flex macro's grams are derived
    /// from percent math.
    private func gramsBinding(_ macro: Macro) -> Binding<Int> {
        Binding(
            get: { grams(macro) },
            set: { newGrams in
                guard calories > 0 else {
                    setGrams(newGrams, macro)
                    return
                }

                recordDirectEdit(macro)
                setGrams(newGrams, macro)
                rebalanceFlex(excluding: macro, editedPercent: percentFromGrams(newGrams, macro))
            }
        )
    }

    /// `nil` when `calories` is 0 — nothing meaningful to show as a
    /// percentage of no budget.
    private func percentOfCalories(_ macro: Macro) -> Int? {
        guard calories > 0 else { return nil }

        return percentFromGrams(grams(macro), macro)
    }

    private func percentFromGrams(_ grams: Int, _ macro: Macro) -> Int {
        guard calories > 0 else { return 0 }

        let macroKcal = Double(grams) * macro.kcalPerGram
        return Int((macroKcal / Double(calories) * 100).rounded())
    }

    /// Percent mode legitimately derives grams from the typed percentage
    /// (percent is the value you're entering here, grams is the
    /// secondary/derived one) — unlike grams mode, there's no verbatim
    /// value to preserve.
    private func percentBinding(_ macro: Macro) -> Binding<Int> {
        Binding(
            get: { percentOfCalories(macro) ?? 0 },
            set: { newPercent in
                guard calories > 0 else { return }

                let clamped = max(0, min(100, newPercent))
                recordDirectEdit(macro)
                setGrams(gramsFromPercent(clamped, macro), macro)
                rebalanceFlex(excluding: macro, editedPercent: clamped)
            }
        )
    }

    private func recordDirectEdit(_ macro: Macro) {
        editOrder.removeAll { $0 == macro }
        editOrder.append(macro)
    }

    /// Leaves whichever of the other two macros was more recently
    /// directly edited untouched at its current value, and puts the
    /// entire remainder onto the macro that's gone longest without being
    /// directly edited (or was never directly edited at all, which
    /// always outranks "edited a while ago"). This never disturbs a
    /// macro you just deliberately set.
    private func rebalanceFlex(excluding macro: Macro, editedPercent: Int) {
        let held = mostRecentlyEditedOther(excluding: macro)
        let flex = Macro.allCases.first { $0 != macro && $0 != held }!

        let heldPercent = percentOfCalories(held) ?? 0
        let flexPercent = max(0, 100 - editedPercent - heldPercent)

        setGrams(gramsFromPercent(flexPercent, flex), flex)
    }

    /// Of the two macros other than `edited`, whichever was directly
    /// edited more recently — a macro never directly edited always loses
    /// to one that has been, however long ago, since "never touched" is
    /// the strongest signal that a macro is safe to auto-adjust.
    private func mostRecentlyEditedOther(excluding edited: Macro) -> Macro {
        let others = Macro.allCases.filter { $0 != edited }

        return others.max {
            (editOrder.firstIndex(of: $0) ?? -1) < (editOrder.firstIndex(of: $1) ?? -1)
        }!
    }

    private func gramsFromPercent(_ percent: Int, _ macro: Macro) -> Int {
        guard calories > 0 else { return 0 }

        let macroKcal = Double(calories) * Double(percent) / 100
        return Int((macroKcal / macro.kcalPerGram).rounded())
    }

    // MARK: - Goal Row / Persistence

    private func goalRow(_ goal: MacroGoal) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(goal.effectiveDate, style: .date)
                .font(AppTheme.Typography.cardTitle)

            Text(
                "\(goal.calories) kcal · P \(goal.proteinG)g · C \(goal.carbsG)g · F \(goal.fatG)g"
            )
            .font(AppTheme.Typography.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    private func prefillFromActiveGoal() {
        guard let active = macroGoalStore.activeGoal(on: .now) else { return }

        calories = active.calories
        proteinG = active.proteinG
        carbsG = active.carbsG
        fatG = active.fatG
    }

    private func saveGoal() {
        macroGoalStore.add(
            MacroGoal(
                effectiveDate: effectiveDate,
                calories: calories,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG
            )
        )
    }
}

private enum MacroEntryMode: String, CaseIterable, Identifiable {
    case grams
    case percent

    var id: String { rawValue }

    var label: String {
        switch self {
        case .grams: return "Grams"
        case .percent: return "Percent"
        }
    }
}

private enum Macro: CaseIterable {
    case protein, carbs, fat

    var label: String {
        switch self {
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fat: return "Fat"
        }
    }

    /// Standard Atwater conversion factors.
    var kcalPerGram: Double {
        switch self {
        case .protein, .carbs: return 4
        case .fat: return 9
        }
    }
}

/// Directly-tappable numeric field for whole-number entry (calories,
/// grams, percent) — same numpad-first interaction as the `Double`-based
/// fields elsewhere in this app (`LogWeightView`, `LogBodyMeasurementsView`,
/// `EditMeasurementEntryView`), just `Int`-typed since macro targets
/// don't need fractional grams. Kept as its own private-per-screen copy
/// per this app's existing convention.
private struct IntEntryField: View {
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

    /// The `parsed != value` guard is load-bearing, not a micro-
    /// optimization: `value`'s setter here has cross-field side effects
    /// (it redistributes the other two macros), and `syncTextFromValue`
    /// below writes back into this same `text` whenever `value` changes
    /// — including when *this* field is the one being auto-adjusted as
    /// someone else's flex partner. Without this guard, that resync
    /// re-enters `updateValueWhileTyping` (text changed → onChange fires
    /// again) and calls the setter a second time with a value that's
    /// already current, which silently re-records this field as "just
    /// directly edited" and corrupts which macro is held vs. flexed on
    /// the next real edit.
    private func updateValueWhileTyping() {
        guard !text.isEmpty else { return }

        if let parsed = Int(text), parsed != value {
            value = parsed
        }
    }

    private func syncTextFromValue() {
        text = String(value)
    }

    private var numericFont: UIFont {
        let base = UIFont.systemFont(ofSize: 30, weight: .bold)
        guard let roundedDescriptor = base.fontDescriptor.withDesign(.rounded) else {
            return base
        }
        return UIFont(descriptor: roundedDescriptor, size: 30)
    }
}
