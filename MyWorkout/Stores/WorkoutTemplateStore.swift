import Foundation

final class WorkoutTemplateStore: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []

    private let key = "workout_templates"

    init() {
        load()

        if templates.isEmpty {
            templates = SeedData.defaultTemplates
            save()
        }
    }

    func add(_ template: WorkoutTemplate) {
        templates.append(template)
        save()
    }

    func delete(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
        save()
    }
    
    func replaceAll(with newTemplates: [WorkoutTemplate]) {
        templates = newTemplates
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save templates: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }

        do {
            templates = try JSONDecoder().decode([WorkoutTemplate].self, from: data)
        } catch {
            print("Failed to load templates: \(error)")
        }
    }
    
    func update(_ template: WorkoutTemplate) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        templates[index] = template
        save()
    }

    func duplicate(_ template: WorkoutTemplate) {
        let copy = WorkoutTemplate(
            name: "\(template.name) Copy",
            exercises: template.exercises
        )

        templates.append(copy)
        save()
    }
}
