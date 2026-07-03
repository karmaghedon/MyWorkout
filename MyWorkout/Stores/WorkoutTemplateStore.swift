import Foundation

final class WorkoutTemplateStore: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []

    @Published private(set) var lastSaveError: String?
    @Published private(set) var lastLoadError: String?

    private let legacyDefaultsKey = "workout_templates"
    private let fileURL: URL
    private let saveQueue = DispatchQueue(label: "com.myworkout.workouttemplatestore.save", qos: .utility)

    init() {
        fileURL = Self.resolveFileURL()
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

    func update(_ template: WorkoutTemplate) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        templates[index] = refreshed(template)
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

    func replaceAll(with newTemplates: [WorkoutTemplate]) {
        templates = newTemplates.map { refreshed($0) }
        save()
    }

    private static func resolveFileURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("MyWorkout", isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory.appendingPathComponent("workout_templates.json")
    }

    private func save() {
        let templatesToSave = templates
        let destination = fileURL

        saveQueue.async { [weak self] in
            do {
                let data = try JSONEncoder().encode(templatesToSave)
                try data.write(to: destination, options: .atomic)

                DispatchQueue.main.async {
                    self?.lastSaveError = nil
                }
            } catch {
                print("Failed to save workout templates: \(error)")

                DispatchQueue.main.async {
                    self?.lastSaveError = "Couldn't save workout templates."
                }
            }
        }
    }

    private func load() {
        if !FileManager.default.fileExists(atPath: fileURL.path),
           let legacyData = UserDefaults.standard.data(forKey: legacyDefaultsKey) {
            if let decoded = try? JSONDecoder().decode([WorkoutTemplate].self, from: legacyData) {
                templates = decoded
                save()
            }

            UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
            return
        }

        guard let data = try? Data(contentsOf: fileURL) else { return }

        do {
            templates = try JSONDecoder().decode([WorkoutTemplate].self, from: data)
                .map { refreshed($0) }
            save()
            lastLoadError = nil
        } catch {
            print("Failed to load workout templates: \(error)")
            lastLoadError = "Couldn't load workout templates."
        }
    }
    
    private func refreshed(_ template: WorkoutTemplate) -> WorkoutTemplate {
        WorkoutTemplate(
            id: template.id,
            name: template.name,
            exercises: template.exercises.map { savedExercise in
                SeedData.exercises.first {
                    $0.id == savedExercise.id || $0.name == savedExercise.name
                } ?? savedExercise
            }
        )
    }
}
