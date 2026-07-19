import SwiftUI

struct CustomExerciseEducationSections: View {
    @Binding var draft: CustomExerciseDraft

    var body: some View {
        Group {
            instructionsSection

            EditableStringListSection(
                title: "Tips",
                addButtonTitle: "Add Tip",
                itemPlaceholder: "Training tip",
                systemImage: "lightbulb",
                items: $draft.tips,
                footer: "Add practical cues that help perform the exercise correctly."
            )

            EditableStringListSection(
                title: "Common Mistakes",
                addButtonTitle: "Add Mistake",
                itemPlaceholder: "Common mistake",
                systemImage: "xmark.circle",
                items: $draft.commonMistakes,
                footer: "Describe technique errors users should avoid."
            )

            EditableStringListSection(
                title: "Safety Warnings",
                addButtonTitle: "Add Warning",
                itemPlaceholder: "Safety warning",
                systemImage: "exclamationmark.triangle",
                items: $draft.warnings,
                footer: "Include important safety or injury-risk guidance."
            )
        }
    }

    private var instructionsSection: some View {
        Section {
            TextEditor(
                text: $draft.instructions
            )
            .frame(minHeight: 140)
            .accessibilityLabel(
                "Exercise instructions"
            )
            .accessibilityHint(
                "Enter step-by-step instructions for performing the exercise."
            )
        } header: {
            Label(
                "Instructions",
                systemImage: "list.number"
            )
        } footer: {
            Text(
                "Write clear, step-by-step guidance for performing the exercise."
            )
        }
    }
}
