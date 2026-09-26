import SwiftUI
import Record
import Programme

/// The "Reviews" list (weekly-review spec, "Finish and reopen a review":
/// "The app MUST offer a 'Reviews' list of finished reviews, newest first.").
/// No row shows an arrow, a colour, a total or a comparison; a tap opens
/// that review. Reached from Today's bottom bar, one tap away, once the
/// first review becomes due (decision 95).
struct ReviewsListView: View {
    let store: RecordStore
    var calendar: Calendar = .current
    /// Pushes the tapped row's review (its week and its own run's start
    /// day) onto the caller's own navigation path, so this screen adds no
    /// `NavigationStack` of its own — the same single-stack shape
    /// `TodayView` already uses for every pushed screen.
    var openReview: (ReviewRunWeek) -> Void

    @State private var rows: [WeeklyReviewModel.ReviewListRow] = []

    var body: some View {
        List {
            if rows.isEmpty {
                // Before the person finishes a review, the list shows no
                // rows and no text about the empty list (decision 95).
                Color.clear.frame(height: 0).accessibilityHidden(true)
            } else {
                ForEach(rows) { row in
                    Button {
                        openReview(row.review)
                    } label: {
                        Text(verbatim: row.text)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .recordListStyle()
        .navigationTitle(ReviewContent.reviewsListTitle)
        .getSupport()
        .onAppear(perform: load)
    }

    private func load() {
        rows = WeeklyReviewModel.reviewsListRows(store: store, calendar: calendar)
    }
}
