import SwiftUI

struct TemplateListView: View {
    @EnvironmentObject var templateStore: WorkoutTemplateStore

    var body: some View {
        List {
            ForEach(templateStore.templates) { template in
                NavigationLink {
                    TemplateEditorView(template: template)
                } label: {
                    VStack(alignment: .leading) {
                        Text(template.name)
                            .font(.headline)

                        Text("\(template.exercises.count) exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: templateStore.delete)
        }
        .navigationTitle("Edit Templates")
    }
}
