import SwiftUI

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

    let onLogSet: () -> Void
    let onStopRest: () -> Void
    let onDeleteSet: (UUID) -> Void
    let onToggleWarmup: (Double, Int) -> Void
    let onAddSet: () -> Void

    @EnvironmentObject var settingsStore: UserSettingsStore

    /// Whether the inline weight/reps editor is showing on the next
    /// (unlogged) working-set row — the Checklist layout otherwise has no
    /// way to deviate from the preset weight before logging, unlike
    /// Classic's always-visible steppers.
    @State private var isEditingNextSet = false

    private var unitSystem: UnitSystem {
        settingsStore.settings.unitSystem
    }

    private var weightUnit: String {
        unitSystem.rawValue
    }

    private var warmups: [WarmupSet] {
        WarmupEngine.generateWarmups(
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
                exerciseName: exercise.name,
                exerciseType: exercise.exerciseType.rawValue.capitalized,
                progressionStrategy: exercise.progressionStrategy.displayName,
                nextSetNumber: nextSetNumber
            )

            PreviousPerformanceView(
                previousSets: previousSets,
                displayWeight: displayWeight,
                weightUnit: weightUnit
            )

            if !warmups.isEmpty {
                warmupChecklist
            }

            workingSetChecklist

            if isResting {
                RestTimerBadge(
                    secondsRemaining: restSecondsRemaining,
                    totalSeconds: restTotalSeconds,
                    onStop: onStopRest
                )
            }

            NotesSectionView(notes: $state.notes)
        }
    }

    private var warmupChecklist: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("WARM-UP")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(AppTheme.secondaryText)

            ForEach(warmups) { warmup in
                SetChecklistRow(
                    title: "\(formatWeight(displayWeight(warmup.weight))) \(weightUnit) × \(warmup.reps)",
                    subtitle: nil,
                    plateText: plateText(for: warmup.weight),
                    isComplete: state.completedWarmupKeys.contains(
                        ExerciseSessionState.warmupKey(weight: warmup.weight, reps: warmup.reps)
                    ),
                    isNext: false,
                    onToggle: { onToggleWarmup(warmup.weight, warmup.reps) },
                    onEdit: nil
                )
            }
        }
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
                        plateText: plateText(for: set.weight),
                        isComplete: true,
                        isNext: false,
                        onToggle: { onDeleteSet(set.id) },
                        onEdit: nil
                    )
                } else if index == state.loggedSets.count {
                    SetChecklistRow(
                        title: "\(formatWeight(displayWeight(state.workingWeightPounds))) \(weightUnit) × \(state.targetReps) (target)",
                        subtitle: nil,
                        plateText: plateText(for: state.workingWeightPounds),
                        isComplete: false,
                        isNext: true,
                        onToggle: {
                            isEditingNextSet = false
                            onLogSet()
                        },
                        onEdit: { isEditingNextSet.toggle() }
                    )

                    if isEditingNextSet {
                        nextSetEditor
                    }
                }
            }

            Button(action: onAddSet) {
                Label("Add Set", systemImage: "plus.circle")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, AppTheme.Spacing.xs)
        }
    }

    /// Inline weight/reps steppers for the next working set — reuses the
    /// exact controls Classic's `CurrentSetCardView` uses, so the two
    /// layouts stay in sync on how weight gets adjusted rather than
    /// inventing a second input pattern.
    private var nextSetEditor: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            DoubleBigStepperControl(
                title: "Weight",
                value: weightDisplayBinding,
                range: 0...500,
                step: displayWeightStep,
                suffix: weightUnit
            )

            BigStepperControl(
                title: "Reps",
                value: $state.targetReps,
                range: 1...50,
                step: 1,
                suffix: nil
            )
        }
        .padding(.top, AppTheme.Spacing.xs)
    }

    private func plateText(for weight: Double) -> String? {
        guard exercise.usesBarbell else { return nil }

        let loading = PlateCalculator.loading(for: weight, inventory: equipmentInventory)
        return "\(loading.displayText(in: equipmentInventory.unitSystem)) \(equipmentInventory.unitSystem.rawValue)/side"
    }

    /// Converts canonical stored pounds into the selected display unit.
    private func displayWeight(_ storedPounds: Double) -> Double {
        WeightConversion.displayWeight(
            fromStoredPounds: storedPounds,
            unitSystem: unitSystem
        )
    }

    // MARK: - Weight Boundary

    /// The session state always stores pounds. This binding converts
    /// between canonical stored pounds and the unit currently selected by
    /// the user — same pattern as `ExerciseSessionCardView`'s.
    private var weightDisplayBinding: Binding<Double> {
        Binding(
            get: {
                displayWeight(state.workingWeightPounds)
            },
            set: { displayedWeight in
                state.workingWeightPounds = WeightConversion.storedPounds(
                    fromDisplayedWeight: displayedWeight,
                    unitSystem: unitSystem
                )
            }
        )
    }

    /// The incoming step is expressed in canonical pounds.
    private var displayWeightStep: Double {
        WeightConversion.displayStep(
            fromStoredPounds: Double(weightStep),
            unitSystem: unitSystem
        )
    }
}
