import SwiftUI

struct EditableStringListSection: View {
    let title: LocalizedStringKey
    let addButtonTitle: LocalizedStringKey
    let itemPlaceholder: LocalizedStringKey
    let systemImage: String

    @Binding var items: [String]

    var footer: LocalizedStringKey?

    var body: some View {
        Section {
            ForEach(items.indices, id: \.self) { index in
                HStack {
                    TextField(
                        itemPlaceholder,
                        text: $items[index]
                    )

                    Button(
                        role: .destructive
                    ) {
                        removeItem(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                            .accessibilityHidden(true)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(
                        "Remove item \(index + 1)"
                    )
                }
            }

            Button {
                addItem()
            } label: {
                Label(
                    addButtonTitle,
                    systemImage: "plus.circle"
                )
            }
        } header: {
            Label(
                title,
                systemImage: systemImage
            )
        } footer: {
            if let footer {
                Text(footer)
            }
        }
    }

    // MARK: - Actions

    private func addItem() {
        items.append("")
    }

    private func removeItem(
        at index: Int
    ) {
        guard items.indices.contains(index) else {
            return
        }

        items.remove(at: index)
    }
}
