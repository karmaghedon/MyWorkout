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
                Text(exerciseType)
                Text("•")
                Text(progressionStrategy)
            }
            .font(AppTheme.Typography.caption)
            .foregroundStyle(.secondary)
        }
    }
}
