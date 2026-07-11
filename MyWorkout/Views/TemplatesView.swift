import SwiftUI

/// The single "manage templates" screen — replaces two separate dashboard
/// entries (Create Template, Edit Templates) that both operated on the
/// same underlying list. Browsing, creating, and editing templates now
/// live in one place, matching the pattern of apps like Reminders' Lists
/// screen: a list with a "+" to add, tap to edit, swipe to delete.
struct TemplatesView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore

    @State private var showingCreateTemplate = false

    var body: some View {
        List {
            ForEach(templateStore.templates) { template in
                NavigationLink {
                    TemplateEditorView(template: template)
                        .id(template.id)
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AppTheme.accentMuted)

                            Image(systemName: "list.bullet.clipboard")
                                .foregroundStyle(AppTheme.accent)
                        }
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.headline)

                            Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: templateStore.delete)
        }
        .overlay {
            if templateStore.templates.isEmpty {
                emptyState
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateTemplate = true
                } label: {
                    Label("New Template", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateTemplate) {
            NavigationStack {
                CreateWorkoutTemplateView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Templates Yet")
                .font(.headline)

            Text("Tap + to build your first workout template.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}
