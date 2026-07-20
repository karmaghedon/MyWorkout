import SwiftUI

struct MyWorkoutTabBar: View {
    let selection: AppTab
    let workoutPresentation: WorkoutTabPresentation
    let onSelect: (AppTab) -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.top, AppTheme.Spacing.xs)
        .padding(.bottom, AppTheme.Spacing.xs)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func tabButton(
        for tab: AppTab
    ) -> some View {
        if tab.isPrimaryDestination {
            primaryButton(for: tab)
        } else {
            standardButton(for: tab)
        }
    }

    private func standardButton(
        for tab: AppTab
    ) -> some View {
        Button {
            onSelect(tab)
        } label: {
            VStack(spacing: 4) {
                Image(
                    systemName: iconName(for: tab)
                )
                .font(.system(size: 20, weight: .semibold))
                .frame(height: 24)

                Text(tab.title)
                    .font(.caption2)
                    .fontWeight(
                        isSelected(tab)
                            ? .semibold
                            : .regular
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(
            isSelected(tab)
                ? Color.accentColor
                : .secondary
        )
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(
            isSelected(tab) ? .isSelected : []
        )
    }

    private func primaryButton(
        for tab: AppTab
    ) -> some View {
        Button {
            onSelect(tab)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 52, height: 52)

                    Image(systemName: tab.systemImage)
                        .font(
                            .system(
                                size: 23,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                }
                .overlay {
                    if isSelected(tab) {
                        Circle()
                            .stroke(
                                Color.primary.opacity(0.14),
                                lineWidth: 3
                            )
                            .frame(width: 58, height: 58)
                    }
                }

                VStack(spacing: 0) {
                    Text(workoutPresentation.title)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if let statusText =
                            workoutPresentation.statusText {
                        Text(statusText)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(
            isSelected(tab)
                ? Color.accentColor
                : .primary
        )
        .accessibilityLabel(
            workoutPresentation.accessibilityLabel
        )
        .accessibilityAddTraits(
            isSelected(tab) ? .isSelected : []
        )
    }

    private func isSelected(
        _ tab: AppTab
    ) -> Bool {
        selection == tab
    }

    private func iconName(
        for tab: AppTab
    ) -> String {
        isSelected(tab)
            ? tab.selectedSystemImage
            : tab.systemImage
    }
}
