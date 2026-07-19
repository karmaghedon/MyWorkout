import SwiftUI

struct CustomExerciseMusclesSection: View {
    @Binding var draft: CustomExerciseDraft

    var body: some View {
        Group {
            EditableStringListSection(
                title: "Primary Muscles",
                addButtonTitle: "Add Primary Muscle",
                itemPlaceholder: "Muscle name",
                systemImage:
                    "figure.strengthtraining.traditional",
                items: $draft.primaryMuscles,
                footer:
                    "Add the muscles that perform most of the work."
            )

            EditableStringListSection(
                title: "Secondary Muscles",
                addButtonTitle: "Add Secondary Muscle",
                itemPlaceholder: "Muscle name",
                systemImage: "figure.arms.open",
                items: $draft.secondaryMuscles,
                footer:
                    "Add supporting or stabilizing muscles."
            )
        }
    }
}
