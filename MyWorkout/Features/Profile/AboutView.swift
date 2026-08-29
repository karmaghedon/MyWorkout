import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.accent)
                        .accessibilityHidden(true)

                    Text("MyWorkout")
                        .font(AppTheme.Typography.screenTitle)

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .accessibilityElement(children: .combine)
            }

            Section("About") {
                Text(
                    "MyWorkout is a local-first strength training tracker — "
                    + "templates, progression, plate math, and analytics, "
                    + "all stored on your device."
                )
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
