import SwiftUI

struct ExerciseSessionHeaderView: View {
    let exerciseName: String
    let exerciseType: String
    let progressionStrategy: String
    let nextSetNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(exerciseName)
                    .font(AppTheme.Typography.screenTitle)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)

                Spacer(minLength: AppTheme.Spacing.md)

                Chip(
                    text: "Set \(nextSetNumber)",
                    font: AppTheme.Typography.label,
                    backgroundColor: AppTheme.accentMuted,
                    foregroundColor: Color.primary
                )
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                Text(exerciseType)
                Text("•")
                Text(progressionStrategy)
            }
            .font(AppTheme.Typography.caption)
            .foregroundStyle(.secondary)
        }
    }
}
