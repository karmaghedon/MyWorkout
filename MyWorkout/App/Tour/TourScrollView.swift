import SwiftUI

/// A drop-in replacement for a screen's own `ScrollView { ... }` that
/// also auto-scrolls to the current tour step's `.tourAnchor(_:)`
/// target whenever the tour requests this screen's tab — several
/// tour-covered screens (Home, Progress, Profile) stack more cards
/// than fit on one screen, so a spotlighted card further down than the
/// first one or two needed to actually be scrolled into view, not just
/// have its (correctly resolved, but off-screen) anchor highlighted.
///
/// Screens that don't need this (anchors that are always above the
/// fold, or `List`-based screens where the anchored content is already
/// near the top) can keep using a plain `ScrollView` — this is purely
/// additive, not a requirement for every tour-anchored screen.
struct TourScrollView<Content: View>: View {
    let tab: AppTab
    @ViewBuilder let content: () -> Content

    @EnvironmentObject private var tourCoordinator: TourCoordinator

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                content()
            }
            .onChange(of: tourCoordinator.requestToken) { _, _ in
                scrollToCurrentStepIfNeeded(proxy: proxy)
            }
            .onAppear {
                scrollToCurrentStepIfNeeded(proxy: proxy)
            }
        }
    }

    private func scrollToCurrentStepIfNeeded(proxy: ScrollViewProxy) {
        guard tourCoordinator.isActive,
              let step = tourCoordinator.currentStep,
              step.tab == tab else {
            return
        }

        withAnimation {
            proxy.scrollTo(step.anchorID, anchor: .center)
        }
    }
}
