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

    private var weightUnit: String {
        settingsStore.settings.weightUnitLabel
    }

    private var warmups: [WarmupSet] {
        WarmupEngine.generateWarmups(
            for: state.weight,
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
                displayWeight: settingsStore.settings.displayWeight,
                weightUnit: weightUnit
            )

            CurrentSetCardView(
                weight: weightDisplayBinding,
                reps: $state.reps,
                weightRange: 0...500.0,
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
                    displayWeight: settingsStore.settings.displayWeight,
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
                            displayWeight: settingsStore.settings.displayWeight,
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
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.accentMuted)
            )
    }

    private var workingLoadRow: some View {
        let loading = PlateCalculator.loading(for: state.weight, inventory: equipmentInventory)

//        return Label(
//            "Working load: \(loading.displayText(in: equipmentInventory.unitSystem)) \(equipmentInventory.unitSystem.rawValue) / side",
//            systemImage: "circle.grid.2x2.fill"
//        )
//        .font(AppTheme.Typography.caption)
//        .foregroundStyle(.secondary)
        return VStack(alignment: .leading, spacing: 2) {
            Label(
                "Working load: \(loading.displayText(in: equipmentInventory.unitSystem)) \(equipmentInventory.unitSystem.rawValue) / side",
                systemImage: "circle.grid.2x2.fill"
            )
            .font(AppTheme.Typography.caption)
            .foregroundStyle(.secondary)
            
            if loading.hasResidue {
                Text("Plates can't match exactlu - closest achievable load")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var weightDisplayBinding: Binding<Double> {
        Binding(
            get: {
                settingsStore.settings.displayWeight(state.weight)
            },
            set: { newDisplayValue in
                state.weight = settingsStore.settings.storageWeight(fromDisplayed: newDisplayValue)
            }
        )
    }

    private var displayWeightStep: Double {
        switch settingsStore.settings.unitSystem {
        case .pounds:
            return Double(weightStep)
        case .kilograms:
            let raw = Double(weightStep) * 0.453592
            return max(0.5, (raw * 2).rounded() / 2) // round to nearest 0.5kg
        }
    }
}
