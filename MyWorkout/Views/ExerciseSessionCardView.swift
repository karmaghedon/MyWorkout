import SwiftUI

struct ExerciseSessionCardView: View {
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
            barbellWeight: equipmentInventory.barbellWeight
        )
    }

    private var nextSetNumber: Int {
        state.loggedSets.count + 1
    }

    var body: some View {
        WorkoutSessionCard {
            ExerciseSessionHeaderView(
                exerciseName: exercise.name,
                exerciseType: exercise.exerciseType.rawValue.capitalized,
                progressionStrategy: exercise.progressionStrategy.displayName,
                nextSetNumber: nextSetNumber
            )

            if let suggestion = state.suggestionMessage {
                suggestionBanner(suggestion)
            }

            PreviousPerformanceView(
                previousSets: previousSets,
                displayWeight: displayWeight,
                weightUnit: weightUnit
            )

            CurrentSetCardView(
                weight: weightDisplayBinding,
                reps: $state.targetReps,
                weightRange: 0...500,
                weightStep: displayWeightStep,
                weightUnit: weightUnit,
                repRange: 1...50,
                nextSetNumber: nextSetNumber,
                onLogSet: onLogSet
            )

            if isResting {
                RestTimerBadge(
                    secondsRemaining: restSecondsRemaining,
                    totalSeconds: restTotalSeconds,
                    onStop: onStopRest
                )
            }

            if !state.loggedSets.isEmpty {
                LoggedSetsView(
                    sets: state.loggedSets,
                    displayWeight: displayWeight,
                    weightUnit: weightUnit,
                    onDeleteSet: onDeleteSet
                )
            }

            DisclosureGroup("Warm-up & plates") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    if !warmups.isEmpty {
                        WarmupSectionView(
                            warmups: warmups,
                            usesBarbell: exercise.usesBarbell,
                            equipmentInventory: equipmentInventory,
                            displayWeight: displayWeight,
                            weightUnit: weightUnit
                        )
                    }

                    if exercise.usesBarbell {
                        workingLoadRow
                    }
                }
                .padding(.top, AppTheme.Spacing.sm)
            }
            .font(AppTheme.Typography.label)
            .tint(AppTheme.accent)

            NotesSectionView(notes: $state.notes)
        }
    }

    private func suggestionBanner(_ text: String) -> some View {
        Label(text, systemImage: "arrow.up.right.circle.fill")
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.accent)
            .padding(AppTheme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(
                    cornerRadius: AppTheme.Radius.control,
                    style: .continuous
                )
                .fill(AppTheme.accentMuted)
            )
    }

    private var workingLoadRow: some View {
        let loading = PlateCalculator.loading(
            for: state.workingWeightPounds,
            inventory: equipmentInventory
        )

        return VStack(alignment: .leading, spacing: 2) {
            Label(
                "Working load: \(loading.displayText(in: equipmentInventory.unitSystem)) \(equipmentInventory.unitSystem.rawValue) / side",
                systemImage: "circle.grid.2x2.fill"
            )
            .font(AppTheme.Typography.caption)
            .foregroundStyle(.secondary)

            if loading.hasResidue {
                Text("Plates can't match exactly — closest achievable load shown.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Weight Boundary

    /// The session state always stores pounds.
    ///
    /// This binding converts between canonical stored pounds and the unit
    /// currently selected by the user.
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

    /// Converts canonical stored pounds into the selected display unit.
    private func displayWeight(_ storedPounds: Double) -> Double {
        WeightConversion.displayWeight(
            fromStoredPounds: storedPounds,
            unitSystem: unitSystem
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
