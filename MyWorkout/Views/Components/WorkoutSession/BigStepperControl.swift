import SwiftUI

struct BigStepperControl: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let suffix: String?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(AppTheme.Typography.eyebrow)
                .foregroundStyle(.secondary)

            Text(valueText)
                .font(AppTheme.Typography.numeric(30))
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            HStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    value = max(range.lowerBound, value - step)
                } label: {
                    Image(systemName: "minus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    value = min(range.upperBound, value + step)
                } label: {
                    Image(systemName: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
    }

    private var valueText: String {
        if let suffix {
            "\(value) \(suffix)"
        } else {
            "\(value)"
        }
    }
}
