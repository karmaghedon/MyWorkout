import SwiftUI

struct NotesSectionView: View {
    @Binding var notes: String

    var body: some View {
        DisclosureGroup("Notes") {
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("How did it feel?")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $notes)
                    .font(AppTheme.Typography.caption)
                    .frame(minHeight: 60)
                    .scrollContentBackground(.hidden)
            }
            .padding(AppTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.subtleFill)
            )
            .padding(.top, AppTheme.Spacing.sm)
        }
        .font(AppTheme.Typography.label)
        .tint(Color.primary)
    }
}
