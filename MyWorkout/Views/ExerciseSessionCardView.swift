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
        WarmupEngine.generateWarmups(for: state.weight, exerciseType: exercise.exerciseType)
    }

    private var nextSetNumber: Int {
        state.loggedSets.count + 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            header

            if let suggestion = state.suggestionMessage {
                suggestionBanner(suggestion)
            }

            previousPerformanceSection

            currentSetPanel

            if isResting {
                RestTimerBadge(
                    secondsRemaining: restSecondsRemaining,
                    totalSeconds: restTotalSeconds,
                    onStop: onStopRest
                )
            }

            if !state.loggedSets.isEmpty {
                loggedSetsSection
            }

            DisclosureGroup("Warm-up & plates") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    if !warmups.isEmpty {
                        warmupSection
                    }

                    if exercise.usesBarbell {
                        workingLoadRow
                    }
                }
                .padding(.top, AppTheme.Spacing.sm)
            }
            .font(AppTheme.Typography.label)
            .tint(AppTheme.accent)

            notesSection
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(exercise.name)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)

                Spacer(minLength: AppTheme.Spacing.md)

                Text("Set \(nextSetNumber)")
                    .font(AppTheme.Typography.label)
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppTheme.accentMuted))
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                Text(exercise.exerciseType.rawValue.capitalized)
                Text("•")
                Text(exercise.progressionStrategy.displayName)
            }
            .font(AppTheme.Typography.caption)
            .foregroundStyle(.secondary)
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

    private var previousPerformanceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("PREVIOUS")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            if previousSets.isEmpty {
                Text("No previous sets recorded")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(previousSets.prefix(3)) { set in
                        Text("\(settingsStore.settings.displayWeight(set.weight)) × \(set.reps)")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(AppTheme.subtleFill))
                    }
                }
            }
        }
    }

    private var currentSetPanel: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("CURRENT SET")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppTheme.Spacing.md) {
                BigStepperControl(
                    title: "Weight",
                    value: weightDisplayBinding,
                    range: 0...500,
                    step: displayWeightStep,
                    suffix: weightUnit
                )

                BigStepperControl(
                    title: "Reps",
                    value: $state.reps,
                    range: 1...50,
                    step: 1,
                    suffix: nil
                )
            }

            Button(action: onLogSet) {
                Label("Log Set \(nextSetNumber)", systemImage: "checkmark.circle.fill")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .fill(AppTheme.subtleFill)
        )
    }

    private var warmupSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("WARM-UP")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            ForEach(warmups) { warmup in
                HStack {
                    Text("\(settingsStore.settings.displayWeight(warmup.weight)) \(weightUnit) × \(warmup.reps)")
                        .font(AppTheme.Typography.caption)

                    if exercise.usesBarbell {
                        Spacer()
                        let loading = PlateCalculator.loading(for: warmup.weight, inventory: equipmentInventory)

                        Text("\(loading.displayText(in: equipmentInventory.unitSystem)) \(equipmentInventory.unitSystem.rawValue) / side")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private var workingLoadRow: some View {
        let loading = PlateCalculator.loading(for: state.weight, inventory: equipmentInventory)

        return Label(
            "Working load: \(loading.displayText(in: equipmentInventory.unitSystem)) \(equipmentInventory.unitSystem.rawValue) / side",
            systemImage: "circle.grid.2x2.fill"
        )
        .font(AppTheme.Typography.caption)
        .foregroundStyle(.secondary)
    }

    private var loggedSetsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("TODAY")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            ForEach(state.loggedSets) { set in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)

                    Text("Set \(set.setNumber)")
                        .font(AppTheme.Typography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(settingsStore.settings.displayWeight(set.weight)) \(weightUnit) × \(set.reps)")
                        .font(AppTheme.Typography.numeric(16))

                    Button {
                        onDeleteSet(set.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete set \(set.setNumber)")
                }
                .padding(.vertical, 6)
            }
        }
    }

    private var notesSection: some View {
        DisclosureGroup("Notes") {
            ZStack(alignment: .topLeading) {
                if state.notes.isEmpty {
                    Text("How did it feel?")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $state.notes)
                    .font(AppTheme.Typography.caption)
                    .frame(minHeight: 60)
                    .scrollContentBackground(.hidden)
            }
            .padding(AppTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.subtleFill)
            )
            .padding(.top, AppTheme.Spacing.sm)
        }
        .font(AppTheme.Typography.label)
        .tint(AppTheme.accent)
    }

    private var weightDisplayBinding: Binding<Int> {
        Binding(
            get: {
                settingsStore.settings.displayWeight(state.weight)
            },
            set: { newDisplayValue in
                state.weight = settingsStore.settings.storageWeight(fromDisplayed: newDisplayValue)
            }
        )
    }

    private var displayWeightStep: Int {
        switch settingsStore.settings.unitSystem {
        case .pounds:
            return weightStep
        case .kilograms:
            return max(1, Int((Double(weightStep) * 0.453592).rounded()))
        }
    }
}

private struct BigStepperControl: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let suffix: String?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            Text(valueText)
                .font(AppTheme.Typography.numeric(30))
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            HStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    value = max(range.lowerBound, value - step)
                } label: {
                    Image(systemName: "minus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    value = min(range.upperBound, value + step)
                } label: {
                    Image(systemName: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private var valueText: String {
        if let suffix {
            return "\(value) \(suffix)"
        }

        return "\(value)"
    }
}
