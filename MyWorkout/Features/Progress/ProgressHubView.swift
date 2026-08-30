import SwiftUI

/// The Progress tab root — per `NavigationArchitecture_F1.1.md` (F6), a
/// lightweight hub organizing History, Analytics, and Strength Trends
/// rather than defaulting straight into one of them. Named `ProgressHubView`
/// rather than the doc's suggested `ProgressView` since that name collides
/// with SwiftUI's own `ProgressView` (the spinner/progress-bar type).
struct ProgressHubView: View {
    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: AppTheme.Spacing.xl
            ) {
                ScreenHeader(title: "Progress")
                    .padding(.horizontal)

                QuickActionSection(title: "Overview") {
                    quickActionLink(
                        systemImage: "clock.arrow.circlepath",
                        title: "History",
                        subtitle: "Browse past workouts",
                        route: .history
                    )

                    Divider()

                    quickActionLink(
                        systemImage: "chart.bar.fill",
                        title: "Analytics",
                        subtitle: "PRs, volume, trends",
                        route: .analytics
                    )

                    Divider()

                    quickActionLink(
                        systemImage: "chart.line.uptrend.xyaxis",
                        title: "Strength",
                        subtitle: "1RM progression",
                        route: .strengthTrends
                    )
                }

                QuickActionSection(title: "Body") {
                    quickActionLink(
                        systemImage: "calendar",
                        title: "Weekly Report",
                        subtitle: "Weight, waist & neck by week",
                        route: .weeklyReport
                    )
                }
            }
            .padding(.bottom)
        }
    }

    private func quickActionLink(
        systemImage: String,
        title: String,
        subtitle: String,
        route: AppRoute
    ) -> some View {
        NavigationLink(value: route) {
            QuickActionRow(
                systemImage: systemImage,
                title: title,
                subtitle: subtitle
            )
        }
        .buttonStyle(.plain)
    }
}
