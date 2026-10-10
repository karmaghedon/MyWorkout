import SwiftUI

/// Dimmed scrim with a cutout over the current step's spotlighted
/// view, plus a callout card explaining it. Mounted once, as an
/// `.overlayPreferenceValue(TourAnchorPreferenceKey.self)` on
/// `AppShellView`'s `TabView` — that's the common ancestor of every
/// `.tourAnchor(_:)`-registered view across all five tabs, which is
/// what lets `anchors` resolve a target mounted in a tab that isn't
/// even frontmost right now.
///
/// The callout stays docked near the bottom of the screen rather than
/// flipping above/below the spotlighted rect — simpler and far more
/// robust to get right without a simulator to iterate in, at the cost
/// of occasionally sitting a little further from its target than a
/// perfectly-adjacent callout would.
struct TourOverlayView: View {
    let anchors: [String: Anchor<CGRect>]

    @EnvironmentObject private var tourCoordinator: TourCoordinator
    @EnvironmentObject private var tourStore: TourStore

    /// Becomes `true` once the current step's anchor has resolved (or
    /// a short timeout elapses) — avoids spotlighting the *previous*
    /// step's position for a frame while a freshly-requested tab/path
    /// switch is still mounting the new destination.
    @State private var showCutout = false

    var body: some View {
        GeometryReader { proxy in
            if tourCoordinator.isActive, let step = tourCoordinator.currentStep {
                ZStack {
                    scrim(for: step, proxy: proxy)

                    VStack {
                        Spacer()
                        calloutCard(for: step)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.bottom, AppTheme.Spacing.xl)
                    }
                }
                .task(id: tourCoordinator.requestToken) {
                    await waitForAnchor(id: step.anchorID)
                }
                .animation(.easeInOut(duration: 0.25), value: showCutout)
            }
        }
        .allowsHitTesting(tourCoordinator.isActive)
        .ignoresSafeArea()
    }

    /// Polls the (live-updating) `anchors` dictionary for up to ~1s —
    /// long enough for a freshly-switched-to tab's root view to mount
    /// and publish its own `.tourAnchor(_:)` preference. Gives up
    /// gracefully (plain callout, no cutout) rather than hanging
    /// forever if a target anchor is ever missing.
    private func waitForAnchor(id: String) async {
        showCutout = false

        for _ in 0..<20 {
            if anchors[id] != nil { break }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        showCutout = true
    }

    @ViewBuilder
    private func scrim(for step: TourStep, proxy: GeometryProxy) -> some View {
        if showCutout, let anchor = anchors[step.anchorID] {
            let rect = proxy[anchor].insetBy(dx: -8, dy: -8)

            Color.black.opacity(0.55)
                .reverseMask {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
        } else {
            Color.black.opacity(0.55)
        }
    }

    private func calloutCard(for step: TourStep) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("\(tourCoordinator.currentStepIndex + 1) of \(tourCoordinator.steps.count)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer()

                Button("Skip", action: finish)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Text(step.title)
                .font(AppTheme.Typography.cardTitle)

            Text(step.message)
                .font(AppTheme.Typography.label)
                .foregroundStyle(AppTheme.secondaryText)

            HStack {
                if tourCoordinator.currentStepIndex > 0 {
                    Button("Back") {
                        tourCoordinator.back()
                    }
                }

                Spacer()

                Button(tourCoordinator.isOnLastStep ? "Done" : "Next") {
                    if tourCoordinator.isOnLastStep {
                        finish()
                    } else {
                        tourCoordinator.next()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .shadow(radius: 12)
    }

    private func finish() {
        tourCoordinator.stop()
        tourStore.markCompleted()
    }
}

private extension View {
    /// Draws `self` everywhere `mask` is *not* — the standard SwiftUI
    /// "reverse mask" recipe (a full-bleed rectangle with `mask`
    /// subtracted via `.destinationOut`, composited as one group so the
    /// blend mode only affects this layer rather than whatever's behind
    /// it). Used here to cut a transparent hole for the spotlighted
    /// element out of the dimmed scrim.
    @ViewBuilder
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask()
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}
