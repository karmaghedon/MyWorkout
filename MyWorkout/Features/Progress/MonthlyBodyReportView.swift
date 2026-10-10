import SwiftUI

/// One month's weekly body-report cards — reached by drilling into a
/// month row on `WeeklyReportView`. Naturally bounded (four or five
/// weeks at most), so unlike the old flat list this never needs its
/// own pagination.
struct MonthlyBodyReportView: View {
    let monthStart: Date
    let cards: [WeeklyBodyReportCard]

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(cards) { card in
                    WeeklyBodyReportCardView(card: card)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(monthStart.formatted(.dateTime.month(.wide).year()))
        .navigationBarTitleDisplayMode(.inline)
    }
}
