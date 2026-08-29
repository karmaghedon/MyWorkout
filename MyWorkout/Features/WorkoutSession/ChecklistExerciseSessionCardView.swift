import SwiftUI
import UIKit

/// The Checklist-layout sibling of `ExerciseSessionCardView` — warm-up and
/// working sets render as tappable checklist rows instead of a single
/// stepper. Shares every piece of data plumbing with the Classic card
/// (warm-up generation, weight-unit conversion, plate math); only the
/// presentation of sets differs.
struct ChecklistExerciseSessionCardView: View {
    let exercise: Exercise
    @Binding var state: ExerciseSessionState
    let previousSets: [LoggedSet]
    let weightStep: Int
    let equipmentInventory: EquipmentInventory

    let isResting: Bool
    let restSecondsRemaining: Int
    let restTotalSeconds: Int

    /// False when this exercise is part of a superset and has already
    /// logged as many sets this round as its least-progressed sibling —
    /// it must wait for the other member(s) before logging another.
    let canLogNextSet: Bool
    let nextSupersetExerciseName: String?

    let onLogSet: () -> Void
    let onStopRest: () -> Void
    let onDeleteSet: (UUID) -> Void
    let onToggleWarmup: (Int, Double, Int) -> Void
    let onUpdateWarmupSet: (Int, Double, Int, [WarmupSet]) -> Void
    let onAddWarmupSet: ([WarmupSet]) -> Void
    let onRemoveWarmupSet: (Int, [WarmupSet]) -> Void
    let onAddSet: () -> Void
    let onRemoveSet: () -> Void

    @EnvironmentObject var settingsStore: UserSettingsStore

    /// Which warm-up row (by position in `warmups`, not `WarmupSet.id`)
    /// currently has its inline weight/reps editor open, if any — only one
    /// at a time. Position rather than id because auto-generated warmups
    /// get a fresh random id every time `warmups` is recomputed (see its
    /// doc comment below), so an id captured here would never match again
    /// on the next render.
    @State private var editingWarmupIndex: Int?

    /// Staged text for the next-set weight/reps fields — not driven
    /// directly by a `Binding` computed from `state`. This card re-renders
    /// on every workout-timer tick (every second, unrelated to anything
    /// the user is doing), and a binding whose `get` always reflects the
    /// last *committed* value would snap an in-progress edit back to that
    /// value on the very next tick — most visibly right after clearing the
    /// field to type a new number, since `Int("")`/`Double("")` fail to
    /// parse and the field's displayed text would revert to the old digits
    /// before the user finishes typing. Same pattern `BigStepperControl`
    /// already uses for exactly this reason.
    @State private var nextSetWeightText = ""
    @State private var nextSetRepsText = ""

    private var unitSystem: UnitSystem {
        settingsStore.settings.unitSystem
    }

    private var weightUnit: String {
        unitSystem.rawValue
    }

    /// Superset/circuit members skip warm-ups entirely — the muscles are
    /// already warm from the prior exercise in the group by the time this
    /// one comes around, so a fresh warm-up ramp would only add
    /// unnecessary sets to log.
    private var warmups: [WarmupSet] {
        guard exercise.supersetGroupID == nil else { return [] }

        if let customWarmups = state.customWarmups {
            return customWarmups
        }

        return WarmupEngine.generateWarmups(
            for: state.workingWeightPounds,
            exerciseType: exercise.exerciseType,
            usesBarbell: exercise.usesBarbell,
            barbellWeight: storedBarbellWeightPounds
        )
    }

    private var nextSetNumber: Int {
        state.loggedSets.count + 1
    }

    private var storedBarbellWeightPounds: Double {
        WeightConversion.toPounds(
            equipmentInventory.barbellWeight,
            from: equipmentInventory.unitSystem
        )
    }

    var body: some View {
        WorkoutSessionCard {
            ExerciseSessionHeaderView(
                exercise: exercise,
                exerciseType: exercise.exerciseType.rawValue.capitalized,
                progressionStrategy: exercise.progressionStrategy.displayName,
                nextSetNumber: nextSetNumber
            )

            PreviousPerformanceView(
                previousSets: previousSets,
                displayWeight: displayWeight,
                weightUnit: weightUnit
            )

            if exercise.supersetGroupID == nil {
                warmupChecklist
            }

            workingSetChecklist

            NotesSectionView(notes: $state.notes)
        }
    }

    private var warmupChecklist: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("WARM-UP")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.secondaryText)

            ForEach(Array(warmups.enumerated()), id: \.offset) { index, warmup in
                SetChecklistRow(
                    title: "\(formatWeight(displayWeight(warmup.weight))) \(weightUnit) × \(warmup.reps)",
                    subtitle: nil,
                    plateLoading: plateLoading(for: warmup.weight),
                    unitSystem: unitSystem,
                    isComplete: state.completedWarmupKeys.contains(
                        ExerciseSessionState.warmupKey(index: index, weight: warmup.weight, reps: warmup.reps)
                    ),
                    isNext: false,
                    onToggle: { onToggleWarmup(index, warmup.weight, warmup.reps) },
                    onEdit: {
                        editingWarmupIndex = (editingWarmupIndex == index) ? nil : index
                    }
                )

                if editingWarmupIndex == index {
                    warmupEditor(for: warmup, at: index)
                }
            }

            Button {
                onAddWarmupSet(warmups)
            } label: {
                Label("Add Warm-up Set", systemImage: "plus.circle")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, AppTheme.Spacing.xs)
        }
    }

    private func warmupEditor(for warmup: WarmupSet, at index: Int) -> some View {
        VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: AppTheme.Spacing.md) {
                DoubleBigStepperControl(
                    title: "Weight",
                    value: warmupWeightBinding(for: warmup, at: index),
                    range: 0...500,
                    step: displayWeightStep,
                    suffix: weightUnit
                )

                BigStepperControl(
                    title: "Reps",
                    value: warmupRepsBinding(for: warmup, at: index),
                    range: 1...50,
                    step: 1,
                    suffix: nil
                )
            }

            // Lets an accidental "Add Warm-up Set" tap (or a set the user
            // simply doesn't want this session) be undone without having
            // to touch the template.
            Button(role: .destructive) {
                editingWarmupIndex = nil
                onRemoveWarmupSet(index, warmups)
            } label: {
                Label("Remove This Set", systemImage: "trash")
                    .font(AppTheme.Typography.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.error)
        }
        .padding(.top, AppTheme.Spacing.xs)
    }

    private func warmupWeightBinding(for warmup: WarmupSet, at index: Int) -> Binding<Double> {
        Binding(
            get: { displayWeight(warmup.weight) },
            set: { displayedWeight in
                onUpdateWarmupSet(
                    index,
                    WeightConversion.storedPounds(
                        fromDisplayedWeight: displayedWeight,
                        unitSystem: unitSystem
                    ),
                    warmup.reps,
                    warmups
                )
            }
        )
    }

    private func warmupRepsBinding(for warmup: WarmupSet, at index: Int) -> Binding<Int> {
        Binding(
            get: { warmup.reps },
            set: { newReps in
                onUpdateWarmupSet(index, warmup.weight, newReps, warmups)
            }
        )
    }

    private var workingSetChecklist: some View {
        // `max(..., loggedSets.count)` is only a safety floor — it should
        // never actually bind in normal use, since `onAddSet` is the only
        // way `loggedSets` can approach the target, but it guarantees a
        // logged set can never end up hidden if the two ever drift (e.g.
        // a set logged from Classic view mid-workout).
        let targetSetCount = max(
            exercise.targetSets + state.extraWorkingSets,
            state.loggedSets.count
        )

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("WORKING SETS")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.secondaryText)

            ForEach(0..<targetSetCount, id: \.self) { index in
                if index < state.loggedSets.count {
                    let set = state.loggedSets[index]
                    SetChecklistRow(
                        title: "\(formatWeight(displayWeight(set.weight))) \(weightUnit) × \(set.reps)",
                        subtitle: nil,
                        plateLoading: plateLoading(for: set.weight),
                        unitSystem: unitSystem,
                        isComplete: true,
                        isNext: false,
                        onToggle: { onDeleteSet(set.id) },
                        onEdit: nil
                    )

                    // Rest sits between the set that was just completed and
                    // whatever comes next — the next working-set row, or
                    // (if this was the last set) the "Add Set" button right
                    // below, rather than trailing the whole card where it's
                    // easy to miss.
                    if isResting && index == state.loggedSets.count - 1 {
                        RestTimerBadge(
                            secondsRemaining: restSecondsRemaining,
                            totalSeconds: restTotalSeconds,
                            onStop: onStopRest
                        )
                        .id(RestTimerBadge.scrollAnchorID(for: exercise.id))
                    }
                } else if index == state.loggedSets.count {
                    nextSetRow
                }
            }

            HStack(spacing: AppTheme.Spacing.md) {
                Button(action: onAddSet) {
                    Label("Add Set", systemImage: "plus.circle")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)

                // Only offered once the extra slot is actually the one
                // showing as "next" — i.e. all of the template's default
                // sets are already logged, so this really is the extra
                // one and removing it visibly drops that row. Tapping
                // "Add Set" before the defaults are done still counts
                // it (targetSetCount grows right away), but there's
                // nothing extra on screen yet for "Remove Set" to
                // undo, so hide it until there is.
                if state.extraWorkingSets > 0 && state.loggedSets.count >= exercise.targetSets {
                    Button(role: .destructive, action: onRemoveSet) {
                        Label("Remove Set", systemImage: "minus.circle")
                            .font(AppTheme.Typography.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.error)
                }
            }
            .padding(.top, AppTheme.Spacing.xs)
        }
    }

    /// The next (unlogged) working set — weight and reps are directly
    /// tappable numeric fields (bringing up the number pad immediately)
    /// rather than requiring a pencil tap to reveal a stepper first, per
    /// the user's request to remove that extra discovery step.
    private var nextSetRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: AppTheme.Spacing.md) {
                Button(action: onLogSet) {
                    ZStack {
                        Circle()
                            .strokeBorder(AppTheme.accent, lineWidth: 2)
                    }
                    .frame(width: 26, height: 26)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark complete: next set")

                HStack(spacing: AppTheme.Spacing.xs) {
                    numericField(text: $nextSetWeightText, width: 52, keyboardType: .decimalPad)
                        .onChange(of: nextSetWeightText) {
                            updateWeightWhileTyping()
                        }
                        .onChange(of: state.workingWeightPounds) {
                            syncNextSetWeightText()
                        }
                        .onAppear {
                            syncNextSetWeightText()
                        }

                    Text(weightUnit)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.secondaryText)

                    Text("×")
                        .foregroundStyle(AppTheme.secondaryText)

                    numericField(text: $nextSetRepsText, width: 40, keyboardType: .numberPad)
                        .onChange(of: nextSetRepsText) {
                            updateRepsWhileTyping()
                        }
                        .onChange(of: state.targetReps) {
                            syncNextSetRepsText()
                        }
                        .onAppear {
                            syncNextSetRepsText()
                        }
                }

                Spacer(minLength: 0)

                if let plateLoading = plateLoading(for: state.workingWeightPounds) {
                    BarbellPlateView(loading: plateLoading, unitSystem: unitSystem)
                }
            }
            // A blocked superset member (see `canLogNextSet`) shows this
            // row dimmed and non-interactive rather than hidden — it's
            // still useful to see the upcoming set's weight/reps, just not
            // to log it until the sibling exercise(s) catch up this round.
            .opacity(canLogNextSet ? 1 : 0.4)
            .allowsHitTesting(canLogNextSet)

            if !canLogNextSet, let nextSupersetExerciseName {
                Label(
                    "Do \(nextSupersetExerciseName)'s set first",
                    systemImage: "arrow.right.circle"
                )
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.accentMuted)
        )
    }

    private func numericField(
        text: Binding<String>,
        width: CGFloat,
        keyboardType: UIKeyboardType
    ) -> some View {
        NumericPadTextField(text: text, keyboardType: keyboardType)
            .frame(width: width)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.subtleFill)
            )
    }

    /// Commits `nextSetWeightText` to `state` only once it parses to a
    /// valid number — an empty or in-progress string (e.g. "72.") is left
    /// as pure UI state rather than forced into `state.workingWeightPounds`,
    /// so clearing the field to type a new value doesn't get immediately
    /// overwritten by the sync triggered from the old committed value.
    private func updateWeightWhileTyping() {
        guard !nextSetWeightText.isEmpty,
              let displayedWeight = Double(nextSetWeightText) else { return }

        state.workingWeightPounds = WeightConversion.storedPounds(
            fromDisplayedWeight: displayedWeight,
            unitSystem: unitSystem
        )
    }

    private func syncNextSetWeightText() {
        nextSetWeightText = formatWeight(displayWeight(state.workingWeightPounds))
    }

    private func updateRepsWhileTyping() {
        guard !nextSetRepsText.isEmpty,
              let reps = Int(nextSetRepsText) else { return }

        state.targetReps = reps
    }

    private func syncNextSetRepsText() {
        nextSetRepsText = "\(state.targetReps)"
    }

    private func plateLoading(for weight: Double) -> PlateLoading? {
        guard exercise.usesBarbell else { return nil }
        return PlateCalculator.loading(for: weight, inventory: equipmentInventory)
    }

    /// Converts canonical stored pounds into the selected display unit.
    private func displayWeight(_ storedPounds: Double) -> Double {
        WeightConversion.displayWeight(
            fromStoredPounds: storedPounds,
            unitSystem: unitSystem
        )
    }

    // MARK: - Weight Boundary

    /// The incoming step is expressed in canonical pounds.
    private var displayWeightStep: Double {
        WeightConversion.displayStep(
            fromStoredPounds: Double(weightStep),
            unitSystem: unitSystem
        )
    }
}
