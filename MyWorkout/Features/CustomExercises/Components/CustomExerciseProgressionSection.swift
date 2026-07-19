import SwiftUI

struct CustomExerciseProgressionSection: View {
    @Binding var draft: CustomExerciseDraft

    var body: some View {
        Section {
            Picker(
                "Progression Strategy",
                selection: $draft.progressionStrategy
            ) {
                ForEach(ProgressionStrategy.allCases) { strategy in
                    Text(strategy.displayName)
                        .tag(strategy)
                }
            }

            Stepper(
                value: $draft.minReps,
                in: 1...100
            ) {
                LabeledContent(
                    "Minimum Reps",
                    value: "\(draft.minReps)"
                )
            }

            Stepper(
                value: $draft.maxReps,
                in: draft.minReps...100
            ) {
                LabeledContent(
                    "Maximum Reps",
                    value: "\(draft.maxReps)"
                )
            }

            Stepper(
                value: $draft.increaseAmount,
                in: 0.5...100,
                step: 0.5
            ) {
                LabeledContent(
                    "Weight Increase",
                    value: formattedWeight(
                        draft.increaseAmount
                    )
                )
            }

            Stepper(
                value: $draft.deloadAmount,
                in: 0.5...100,
                step: 0.5
            ) {
                LabeledContent(
                    "Deload Amount",
                    value: formattedWeight(
                        draft.deloadAmount
                    )
                )
            }

            Stepper(
                value: $draft.stallLimit,
                in: 1...10
            ) {
                LabeledContent(
                    "Stall Limit",
                    value: "\(draft.stallLimit)"
                )
            }
        } header: {
            Label(
                "Progression",
                systemImage: "chart.line.uptrend.xyaxis"
            )
        } footer: {
            Text(
                "Define how the app should progress or deload "
                + "this exercise over time."
            )
        }
        .onChange(of: draft.minReps) { _, newValue in
            if draft.maxReps < newValue {
                draft.maxReps = newValue
            }
        }
    }

    private func formattedWeight(
        _ value: Double
    ) -> String {
        if value.rounded() == value {
            return String(
                format: "%.0f",
                value
            )
        }

        return String(
            format: "%.1f",
            value
        )
    }
}
