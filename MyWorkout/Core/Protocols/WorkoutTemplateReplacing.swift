import Foundation

@MainActor
protocol WorkoutTemplateReplacing {
    func replaceAll(
        with newTemplates: [WorkoutTemplate]
    )
}

extension WorkoutTemplateStore:
    WorkoutTemplateReplacing {}
