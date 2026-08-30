import SwiftUI

/// Home's daily calorie/macro summary. Reads directly from
/// `DailyNutritionLogStore`/`MacroGoalStore` — both already-reactive
/// `ObservableObject`s that resolve synchronously (`entry(on:)`,
/// `activeGoal(on:)`), so unlike the original plan for this card there
/// is no async loading step: that plan predated Phase 3's redirection
/// away from a HealthKit `totalsToday()` query to a single local daily
/// record.
struct TodayNutritionCard: View {
    @EnvironmentObject private var dailyNutritionLogStore: DailyNutritionLogStore
    @EnvironmentObject private var macroGoalStore: MacroGoalStore

    var body: some View {
        NavigationLink(value: AppRoute.logNutrition) {
            AppCard {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    header

                    if let goal {
                        caloriesProgress(goal: goal)
                        macroBars(goal: goal)
                    } else {
                        noGoalState
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private var todaysEntry: DailyNutritionLog? {
        dailyNutritionLogStore.entry(on: .now)
    }

    private var goal: MacroGoal? {
        macroGoalStore.activeGoal(on: .now)
    }

    private var header: some View {
        HStack {
            Text("Today's Nutrition")
                .font(AppTheme.Typography.cardTitle)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func caloriesProgress(goal: MacroGoal) -> some View {
        let consumed = todaysEntry?.calories ?? 0

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("\(consumed) / \(goal.calories) kcal")
                .font(AppTheme.Typography.numeric(20))

            ProgressView(
                value: min(Double(consumed), Double(goal.calories)),
                total: Double(max(goal.calories, 1))
            )
            .tint(AppTheme.accent)
        }
    }

    private func macroBars(goal: MacroGoal) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            macroRow(label: "Protein", consumed: todaysEntry?.proteinG ?? 0, target: goal.proteinG)
            macroRow(label: "Carbs", consumed: todaysEntry?.carbsG ?? 0, target: goal.carbsG)
            macroRow(label: "Fat", consumed: todaysEntry?.fatG ?? 0, target: goal.fatG)
        }
    }

    private func macroRow(label: String, consumed: Int, target: Int) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 56, alignment: .leading)

            ProgressView(
                value: min(Double(consumed), Double(target)),
                total: Double(max(target, 1))
            )
            .tint(AppTheme.accent)

            Text("\(consumed)/\(target)g")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var noGoalState: some View {
        Text("Set a macro goal in Profile to track your progress here.")
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.secondaryText)
    }
}
