# App Tour

## Purpose

A live, spotlight-style walkthrough of the app's main capabilities —
auto-starts once for a new user and can be replayed anytime from
Profile. Previously flagged as deferred future work (`Docs/Development/
DevelopmentRoadmap.md`'s "in-app walkthrough/onboarding tool" entry);
this is that feature.

Unlike a slideshow, the tour actually drives the app: it switches tabs
and pushes real screens while a dimmed overlay spotlights the live UI
element being explained, with Next/Back/Skip controls riding alongside.

## Main types (`App/Tour/`)

- `TourStep` — one stop: `tab`, `path` (almost always empty — every
  step targets a tab's root hub/list, not a pushed detail screen),
  `anchorID`, `title`/`message`. `TourStep.all` holds the full,
  hand-written sequence (see Content below).
- `TourAnchorPreferenceKey` + `View.tourAnchor(_ id:)` — an
  `anchorPreference` modifier any target view applies to itself,
  merging into one `[String: Anchor<CGRect>]` dictionary that bubbles
  up to `AppShellView`'s `.overlayPreferenceValue`. Also applies
  `.id(id)` to the same view, so `TourScrollView` can
  `ScrollViewProxy.scrollTo(id:)` it.
- `TourCoordinator` — `isActive`, `currentStepIndex`, `currentStep`.
  `start()`/`next()`/`back()` advance the step and bump a
  `requestToken`; `AppShellView` observes that token and applies the
  new step's `tab`/`path` to its own `@State` (see Why a token, and not
  a shared navigation store below).
- `TourStore` — `hasCompletedTour`, `UserDefaults`-backed exactly like
  `FavoriteExercisesStore` (constructor-injected `UserDefaults`,
  `@Published private(set)`, manual load/save, no `@AppStorage`,
  excluded from `MyWorkoutApp.flushAllPendingSaves()` — low-stakes flag,
  not a data-loss concern).
- `TourOverlayView` — the dimmed scrim + cutout + callout card. Docked
  near the bottom of the screen rather than flipping above/below the
  spotlighted rect — simpler and far more robust to get right without a
  simulator to iterate in.
- `TourScrollView` — a drop-in `ScrollView` replacement (`ScrollViewReader`
  under the hood) that auto-scrolls to the current step's anchor
  whenever the tour requests this screen's tab. Used by `DashboardView`,
  `ProgressHubView`, and `ProfileHubView` — screens that stack more
  cards than fit on one screen, where a spotlighted card further down
  needed to actually scroll into view, not just have its (correctly
  resolved, but off-screen) anchor highlighted.

## Why a token, and not a shared navigation store

`AppShellView` owns tab selection and per-tab navigation paths as
private `@State` (`selectedTab`, five `<tab>Path: [AppRoute]` arrays) —
nothing outside it can switch tabs or push a route directly. Rather
than a larger refactor lifting that state into a shared store, the tour
publishes a "go here next" request (`currentStep` + `requestToken`) and
`AppShellView` applies it to its own state, the same way it already
self-drives navigation in `handleTabSelection`/`routeToActiveWorkout`.

`requestToken` exists because `start()` always resets
`currentStepIndex` to `0`: replaying the tour from a state where it's
already sitting at index `0` (including the very first ever `start()`)
wouldn't fire a plain `onChange(of: currentStepIndex)`, and the first
step's tab/path would never get applied. The token changes on every
`start()`/`next()`/`back()` regardless of whether the index actually
moved.

## Toolbar buttons can't be spotlighted

Two early step targets — "Custom Exercises" in the Library tab's
toolbar and "Manage Templates" in the Workout tab's toolbar — never
highlighted when first implemented: a `ToolbarItem`'s content renders
through a separate hosting hierarchy that doesn't propagate the
`.tourAnchor(_:)` preference the overlay reads. Rather than fight that
SwiftUI limitation, both destinations gained a second, ordinary
in-content link (`ExerciseLibraryView`'s "Manage Custom Exercises" row,
`StartWorkoutView`'s "Manage Templates" row) that reaches the exact
same place — a reasonable discoverability win on its own, not just a
tour workaround — alongside the existing toolbar shortcut, which stays
for muscle-memory. **Any future tour step must target a view in the
main content area, never a toolbar item.**

## Off-screen anchors need scrolling, not just highlighting

A `.tourAnchor(_:)`'d view's `Anchor<CGRect>` resolves correctly even
when the view is scrolled out of the visible viewport — the cutout then
draws at the right position, just somewhere the user can't see, which
reads as "nothing highlighted." `TourScrollView` fixes this for the
three screens that need it; a screen with every anchor already above
the fold (or a `List`-based screen where the anchored content sits near
the top) can keep a plain `ScrollView`/`List`.

## Content

One step per major capability area rather than every sub-screen —
14 steps total: Home (hero/start-workout, This Week, Log Weight,
Today's Nutrition), Library (browse/search, custom exercises), Workout
(start from template, manage templates), Progress (History/Analytics/
Strength overview, Body trends), Profile (Settings, Macro Goals,
Equipment, Backup & Data).

## Triggers

- **Auto-start**: `AppShellView.onAppear`, once per launch
  (`hasCheckedTourAutoStart`), only when `!tourStore.hasCompletedTour`
  and no workout is active — several steps assume no active session.
  Starts ~0.5s after Home first appears, not instantly.
- **Manual replay**: Profile → Help → "Take the Tour"
  (`ProfileHubView`), a `Button` (not a route-based `NavigationLink`,
  since starting a tour is a side effect) — disabled while a workout is
  active, same reasoning as auto-start.

Finishing the last step or tapping Skip both call
`TourOverlayView.finish()`, which stops the coordinator and marks
`TourStore` completed — Skip counts as "seen it," not "show it again
next launch."

## Regression focus

- auto-start fires once per launch, only for a user who hasn't
  completed the tour and isn't mid-workout
- every step's spotlight lands on the correct element, scrolling it
  into view first if it isn't already visible
- Back/Next/Skip all behave correctly at the first and last step
  (no "Back" before step 1, "Done" instead of "Next" on the last step)
- replaying from Profile works regardless of `hasCompletedTour`
- toolbar-only destinations are never used as a tour anchor target
