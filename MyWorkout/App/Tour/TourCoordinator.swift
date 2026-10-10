import Foundation

/// Drives the live-spotlight app tour. `AppShellView` owns tab
/// selection and per-tab navigation paths as private `@State` (and
/// stays that way — see `Docs/Features/Tour.md` for why this wasn't
/// refactored into a shared store), so this coordinator can't reach in
/// and set them directly. Instead it publishes `currentStep` plus a
/// `requestToken` that changes on every `start()`/`next()`/`back()`
/// call, and `AppShellView` observes that token and applies the
/// current step's `tab`/`path` to its own state — a one-way "go here
/// next" request rather than this coordinator owning navigation.
///
/// `requestToken` exists because `start()` always resets
/// `currentStepIndex` to `0`: if the tour is replayed while already
/// sitting at index `0` (e.g. immediately after a previous run
/// finished on a later step and got reset — or simply the very first
/// ever `start()`, which begins at the default `0`), a plain
/// `onChange(of: currentStepIndex)` wouldn't fire, and the first
/// step's tab/path would never actually get applied.
@MainActor
final class TourCoordinator: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var currentStepIndex = 0
    @Published private(set) var requestToken = UUID()

    let steps: [TourStep] = TourStep.all

    var currentStep: TourStep? {
        steps.indices.contains(currentStepIndex) ? steps[currentStepIndex] : nil
    }

    var isOnLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    func start() {
        currentStepIndex = 0
        isActive = true
        requestToken = UUID()
    }

    func next() {
        guard !isOnLastStep else { return }
        currentStepIndex += 1
        requestToken = UUID()
    }

    func back() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        requestToken = UUID()
    }

    /// Dismisses the overlay. Doesn't touch `TourStore` — the caller
    /// (`TourOverlayView`) marks completion itself, since whether
    /// stopping mid-tour (Skip) should still count as "completed" is a
    /// product decision belonging to the UI layer, not this
    /// coordinator's step-sequencing responsibility.
    func stop() {
        isActive = false
    }
}
