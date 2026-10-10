import SwiftUI

/// Merges every `.tourAnchor(_:)`-registered view's bounds into one
/// dictionary, keyed by the id each view registered itself under.
/// Bubbles up through `TabView`/`NavigationStack` boundaries like any
/// SwiftUI preference — a view doesn't need to be the frontmost tab for
/// its anchor to be resolvable here, only mounted (and since `TabView`
/// keeps a tab's content alive once it's been visited once rather than
/// tearing it down on switch, an anchor stays resolvable after that).
struct TourAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [String: Anchor<CGRect>],
        nextValue: () -> [String: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Registers this view's bounds under `id` for `TourOverlayView` to
    /// spotlight. A pure preference — safe to apply to any already-
    /// shipped view, with no effect on layout or rendering unless a
    /// tour is actually active and targeting this id. Same naming
    /// spirit as `ExerciseSessionHeaderView.scrollAnchorID`/
    /// `RestTimerBadge.scrollAnchorID`, generalized into a reusable
    /// modifier since the tour needs this on a dozen different views
    /// rather than just one.
    func tourAnchor(_ id: String) -> some View {
        self
            // Gives `TourScrollView` something stable to
            // `ScrollViewProxy.scrollTo(_:)` — an off-screen anchor
            // (anything below the fold in a multi-card scroll screen)
            // otherwise resolves to a rect outside the visible
            // viewport, which reads as "nothing highlighted" even
            // though the anchor itself did resolve correctly.
            .id(id)
            .anchorPreference(
                key: TourAnchorPreferenceKey.self,
                value: .bounds
            ) { anchor in
                [id: anchor]
            }
    }
}
