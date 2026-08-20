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
    let equipmentInventory: EquipmentInventory

    let isResting: Bool
    let restSecondsRemaining: Int
    let restTotalSeconds: Int

    let onLogSet: () -> Void
    let onStopRest: () -> Void
    let onDeleteSet: (UUID) -> Void
    let onToggleWarmup: (Double) -> Void
    let onAddSet: () -> Void

    @EnvironmentObject var settingsStore: UserSettingsStore

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
                    isComplete: state.completedWarmupWeights.contains(warmup.weight),
                    isNext: false,
                    onToggle: { onToggleWarmup(warmup.weight) }
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
                        onToggle: { onDeleteSet(set.id) }
                    )
                } else if index == state.loggedSets.count {
                    SetChecklistRow(
                        title: "\(formatWeight(displayWeight(state.workingWeightPounds))) \(weightUnit) × \(state.targetReps) (target)",
                        subtitle: nil,
                        plateText: plateText(for: state.workingWeightPounds),
                        isComplete: false,
                        isNext: true,
                        onToggle: onLogSet
                    )
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
}
