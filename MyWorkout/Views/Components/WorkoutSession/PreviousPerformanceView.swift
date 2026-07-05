import SwiftUI

struct PreviousPerformanceView: View {
    
    let previousSets: [LoggedSet]
    let displayWeight: (Int) -> Int
    let weightUnit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("PREVIOUS")
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            if previousSets.isEmpty {
                Text("No previous sets recorded")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(previousSets.prefix(3)) { set in
                            Text("\(displayWeight(set.weight)) \(weightUnit) × \(set.reps)")
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
    }
}
