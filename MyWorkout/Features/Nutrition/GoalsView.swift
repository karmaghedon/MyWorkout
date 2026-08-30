import SwiftUI

/// Sets and reviews calorie/macro targets. A goal takes effect on a chosen
/// date, and `MacroGoalStore.activeGoal(on:)` resolves which one applies to
/// any given day — this screen is where that history is built and browsed,
/// not where "today's" resolved goal is shown (that's the Home nutrition
/// card, added in a later phase).
struct GoalsView: View {
    @EnvironmentObject private var macroGoalStore: MacroGoalStore

    @State private var effectiveDate = Date.now
    @State private var calories = 2_000
    @State private var proteinG = 150
    @State private var carbsG = 200
    @State private var fatG = 65

    var body: some View {
        List {
            Section {
                DatePicker(
                    "Effective Date",
                    selection: $effectiveDate,
                    displayedComponents: .date
                )

                BigStepperControl(
                    title: "Calories",
                    value: $calories,
                    range: 0...10_000,
                    step: 50,
                    suffix: "kcal"
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                BigStepperControl(
                    title: "Protein",
                    value: $proteinG,
                    range: 0...500,
                    step: 5,
                    suffix: "g"
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                BigStepperControl(
                    title: "Carbs",
                    value: $carbsG,
                    range: 0...500,
                    step: 5,
                    suffix: "g"
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                BigStepperControl(
                    title: "Fat",
                    value: $fatG,
                    range: 0...500,
                    step: 5,
                    suffix: "g"
                )
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
    }

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
