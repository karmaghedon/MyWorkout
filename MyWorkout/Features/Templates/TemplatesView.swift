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
                    WorkoutCard(
                        systemImage: "list.bullet.clipboard",
                        title: template.name
                    ) {
                        Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
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
        AppEmptyStateView(
            title: "No Templates Yet",
            message: "Tap + to build your first workout template.",
            systemImage: "list.bullet.rectangle"
        )
    }
}
