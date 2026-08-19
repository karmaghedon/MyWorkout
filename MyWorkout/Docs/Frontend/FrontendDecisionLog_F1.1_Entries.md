# Frontend Decision Log — F1.1 Entries

**Version:** 1.3  
**Date:** 2026-08-19  
**Status:** Approved

## FDL-001 — Five durable destinations

**Decision**  
Use Home, Library, Workout, Progress, and Profile as the permanent top-level destinations.

**Reason**  
These represent scalable product areas rather than individual features. History belongs to Progress; templates belong to Workout; equipment and backup belong to Profile.

**Consequences**
- Introduce a native five-tab app shell.
- Remove the dashboard's role as a global application menu.
- Each tab receives an independent `NavigationStack`.

---

## FDL-002 — Workout occupies the center position

**Decision**  
Place Workout at the center of the tab bar and allow it to receive distinctive visual emphasis in a later phase.

**Reason**  
Starting or resuming training is MyWorkout's primary user action.

**Consequences**
- Native semantics are established before custom styling.
- Visual emphasis must not move workout business logic into the tab bar.

---

## FDL-003 — Active workout is stateful navigation

**Decision**  
The Workout destination reflects `ActiveWorkoutStore` state: Workout when idle, Resume when active, and concise rest status while resting.

**Reason**  
An in-progress session is more important than offering another start action and must never be silently replaced.

**Consequences**
- The tab shell observes active-workout state but does not mutate it.
- Resume routes to the existing session in the Workout stack.
- Existing replacement confirmation behavior remains mandatory.

---

## FDL-004 — Independent navigation stacks

**Decision**  
Each tab owns its own `NavigationStack` and path.

**Reason**  
Users expect tab state to remain intact when switching destinations. A global stack creates coupling and confusing Back behavior.

**Consequences**
- Navigation state survives tab switches.
- Routes cannot accidentally push into an unrelated destination.
- Feature route ownership can be introduced incrementally later.

---

## FDL-005 — Modal creation, pushed browsing and editing

**Decision**  
Use sheets for bounded creation flows and push navigation for browsing, details, and most editing.

**Reason**  
Creation is a temporary task returning to the current context; detail navigation represents location within the product hierarchy.

**Consequences**
- Create Template remains a sheet.
- Create Custom Exercise becomes a sheet.
- Exercise Detail, Workout Detail, Template Editor, and Custom Exercise editing remain pushes.

---

## FDL-006 — Workout session remains a push destination

**Decision**  
Keep `WorkoutSessionView` as a push destination during F1 rather than converting it to a full-screen cover.

**Reason**  
Native navigation is easier to reason about, test, restore, and make accessible. Immersive presentation can be reconsidered after UX testing.

**Consequences**
- Workout owns the session route.
- Leaving the screen does not cancel the session or timers.
- A custom full-screen experience is explicitly deferred.

---

## FDL-007 — Relocate custom exercises to Library

**Decision**  
Custom exercise management belongs to Library.

**Reason**  
Custom exercises are content in the exercise encyclopedia, not app configuration.

**Consequences**
- Remove Custom Exercises from the dashboard/manage grouping.
- Library becomes the entry point for built-in and user-created exercise content.

---

## FDL-008 — Present Export as Backup & Data

**Decision**  
Keep the source type temporarily but present `ExportView` as Backup & Data under Profile.

**Reason**  
The current feature includes import, export, and backup responsibilities; “Export” is too narrow.

**Consequences**
- User-facing title changes later in a focused UI step.
- A source-file rename is optional and should not be bundled into F1.2.

---

## FDL-009 — Defer feature-specific route enums

**Decision**  
Do not split `AppRoute` into several feature route enums in the same commit that introduces the app shell.

**Reason**  
That would combine two architectural concepts and increase migration risk.

**Consequences**
- F1.2 may temporarily reuse existing route mechanisms.
- Route ownership becomes a separate build-safe refactor after independent stacks are working.

---

## FDL-010 — Fix accent contrast by changing pairing, not the brand color

**Decision**  
Keep the ember-orange accent at full saturation. Where it failed WCAG AA
as text/icon foreground or as white-on-accent inside a filled button,
change the *pairing* instead: black content (`AppTheme.onAccentFill`) on
a solid accent fill, `Color.primary` on an accent-tinted (`accentMuted`)
surface. Purely decorative icons may keep using accent as their own
color.

**Reason**  
A `/mobile-app-design` audit measured white-on-accent at 3.15:1 (needs
4.5:1) and accent-as-text on `accentMuted` at 2.65–4.47:1 depending on
mode — both below the WCAG AA floor. The accent orange is the app's
signature color and a deliberate brand choice; darkening it to pass
contrast was rejected in favor of fixing where it functions as
foreground content versus decoration.

**Consequences**
- Every solid-accent-fill button (`PrimaryButton`, `FloatingActionButton`,
  the Log Set / Add / Finish Workout buttons) now sets its label color
  explicitly rather than relying on the system's automatic white.
- `SecondaryButton` and other bordered/tinted-text controls that
  previously tinted `AppTheme.accent` now tint `Color.primary`.
- Decorative icons (timer glyphs, badge icons) were left unchanged —
  they clear the more permissive 3:1 non-text threshold already.

---

## FDL-011 — AccentColor asset must mirror AppTheme.accent

**Decision**  
Populate the `AccentColor` asset catalog entry with the same RGB value as
`AppTheme.accent`, and replace remaining `Color.accentColor` references
in `MyWorkoutTabBar` with `AppTheme.accent` directly.

**Reason**  
`AccentColor.colorset` had no color defined, so any control relying on
the system's implicit accent tint (the tab bar's selection highlight, the
Workout tab's circle badge) silently fell back to default iOS blue
instead of the app's orange — visible as a mix of orange and blue icons
across the app.

**Consequences**
- The asset catalog and `AppTheme.accent` are now two copies of the same
  value; if the brand color ever changes, both need updating.
- The Workout tab's circle-badge icon also picked up the FDL-010 fix
  (`AppTheme.onAccentFill` instead of hardcoded white), since its
  background is now genuinely the accent orange rather than blue.

---

## FDL-012 — Appearance mode lives in UserSettings, not a separate store

**Decision**  
Add a Day/Night/Auto appearance override as `AppearanceMode` on the
existing `UserSettings` model, surfaced in `SettingsView` under a new
"Appearance" section, applied via `.preferredColorScheme` in
`AppShellView`.

**Reason**  
It's a single user preference with the same persistence, defaulting, and
backward-compatible-decoding needs as every other setting (unit system,
rest timers, 1RM formula) — introducing a dedicated store would duplicate
that machinery for one field. `AppearanceMode` itself is Foundation-only
(no `ColorScheme` import) so the Domain layer stays free of SwiftUI; the
View-layer mapping to `ColorScheme` happens in `AppShellView`.

**Consequences**
- Old saved settings without `appearanceMode` decode to `.system`
  (Auto) via the same `decodeIfPresent ?? defaults` pattern already used
  for every other field — no schema version bump needed.
- Any code constructing `UserSettings` directly (tests included) must
  now supply `appearanceMode`.

---

## FDL-013 — Home becomes a today-focused screen, not a menu

**Decision**
Redesign `DashboardView` (Home) around a greeting header, a single
stateful hero action (start or resume a workout), the existing
`DashboardStatsView` overview, and a preview of recent activity — and
drop the menu cards that now duplicate a permanent tab: Start Workout
(Workout tab), History (Progress tab), and Settings (Profile tab).
Templates, Equipment, Custom Exercises, and Backup & Data remain on Home,
presented as compact `QuickActionRow` rows grouped under "Progress" and
"Manage," since Workout and Profile haven't absorbed them yet.

**Reason**
FDL-001 already named Home's menu role as something to remove, but F1
only introduced the tab shell — it didn't touch Home's content. Leaving
the full original card menu in place after the shell landed meant three
destinations were reachable two ways (Home card and tab root), which
contradicts "Minimal taps" and "Never surprise the user" from
`UXPrinciples_F1.0.md`. The remaining four destinations have no other
home yet, so removing their links would create dead ends rather than
consolidate navigation.

**Consequences**
- `DashboardView` gains a required `onStartWorkout: () -> Void`,
  supplied by `AppShellView` as `{ handleTabSelection(.workout) }` — the
  same tab-switch-and-resume logic the tab bar's Workout item already
  uses, so Home's hero action and the tab bar can never disagree about
  what "start/resume" means.
- New `QuickActionRow` component (compact icon + title + subtitle +
  chevron) replaces `InformationCard` for these menu-style destinations.
  `InformationCard` no longer has a consumer in the codebase as of this
  change but is left in place — it's a reasonable fit for a future
  screen's tile-style content and deleting it isn't this phase's concern.
- Templates, Equipment, Custom Exercises, and Backup & Data staying on
  Home is a deliberate placeholder, not a final decision — F5 (Library)
  and F7 (Profile) are expected to relocate them per FDL-001, at which
  point Home's "Manage" section should shrink or disappear.
- The Export destination's Home-facing label changes to "Backup & Data"
  per FDL-008's recommended user-facing name; the underlying `ExportView`
  type and route are unchanged.

---

## FDL-014 — Enforce AppTheme tokens, touch targets, and VoiceOver labeling across every screen, not just new ones

**Decision**
Run a screen-by-screen audit of every Feature screen — not just the ones
F2/F3 touched directly — against three concrete rules: every piece of
custom UI text uses an `AppTheme.Typography` token instead of a raw
system font; every custom-drawn interactive control (not a native
SwiftUI control) guarantees a 44×44pt minimum touch target; and every
purely decorative icon sitting next to text that already conveys the
same information is hidden from VoiceOver. Fix violations in place
rather than filing them for a later phase.

**Reason**
F2 built the design-token system and shared component library, but
didn't retrofit every screen onto it — several still had raw
`.headline`/`.caption`/`.subheadline` fonts, and a handful of hand-rolled
buttons (a 28×28pt delete button, unguarded stepper +/- controls, a
borderless restore icon) had no touch-target guarantee despite the
shared library having already established the `.frame(minHeight: 44)`/
`IconButton` pattern for exactly this. Leaving these in place would let
the design system's own stated rule — "every one reads from `AppTheme`…
rather than hardcoded values," `ComponentLibrary_F1.0.md` — go stale the
same way the roadmap itself had gone stale before FDL-013's correction.

**Consequences**
- Screens touched: WorkoutSession, Dashboard, Exercise Library,
  Templates, Analytics, Equipment Inventory, Custom Exercises, History.
  Settings and Export were audited and found already clean — built
  entirely from native `Form`/`Picker`/`Stepper`, no custom styling.
- Shared library components fixed for the same reasons: `WorkoutCard`,
  `MetricCard`, `InfoBadge`, `ProgressBadge`, `LoadingState`,
  `AppEmptyStateView`, `ErrorState`, `InformationCard`, `MetricView` —
  see `ComponentLibrary_F1.0.md` for the specific fix on each.
- Touch-target fixes: `BigStepperControl`/`DoubleBigStepperControl`'s
  +/- buttons, `LoggedSetsView`'s delete-set button (converted to
  `IconButton`), `InventoryItemRow`'s delete button, `CustomExerciseRow`'s
  restore button (converted to `IconButton`), `EditableStringListSection`'s
  remove-item button (backs five separate lists in the custom-exercise
  form), and two "show/load more" pagination links (Exercise Library,
  History).
- A related bug surfaced during F3 QA — not from this audit directly,
  but from the same "does this actually work outside its original
  context" scrutiny: `WorkoutCard` had no trailing `Spacer()`, so it only
  ever filled its own content width. Invisible in every prior consumer
  (all inside a `List`, whose rows auto-stretch to full width) until
  Home's new Recent Activity section put it in a plain `VStack` for the
  first time and every row centered instead of staying left-aligned.
  Fixed at the component level — see `ComponentLibrary_F1.0.md`.
- This is a consistency/correctness pass, not the formal "F10 —
  Accessibility" phase — it doesn't cover Dynamic Type at accessibility
  text sizes, VoiceOver navigation order across a full flow, or Reduce
  Motion. `ReleaseChecklist.md` §12 ("UI and accessibility") and
  `DevelopmentRoadmap.md`'s Phase 20 "accessibility review" item remain
  unchecked; this entry is groundwork for that review, not a substitute
  for it.

---

## FDL-015 — Rest-timer feedback and workout-session screen wake

**Decision**
Wire the previously-unused `Haptics.restComplete()` call to the rest
timer's actual completion — only from the live per-second countdown, not
from the app-launch restore path, so reopening the app after a timer
finished in the background doesn't buzz unexpectedly — add a short
system sound alongside it, and disable the idle timer for the duration
of the active-workout screen.

**Reason**
`Haptics.restComplete()` existed with a doc comment describing "the rest
timer running out" as its exact purpose but was never called from
anywhere — dead code for its documented use case, found while auditing
haptic/feedback consistency at the user's request. The sound and
screen-wake additions came directly from user feedback while testing the
haptic fix: haptics alone are silenced by the system-wide "System
Haptics" setting (confirmed via Apple's own developer guidance, which
states this can't be detected or overridden by an app — Core Haptics is
gated by the same setting, not an escape hatch), so a sound gives users a
second, independent feedback channel; and a workout session is exactly
the kind of long, hands-off-the-screen interaction the idle timer isn't
designed for.

**Consequences**
- `Haptics.restComplete()` now fires from
  `ActiveWorkoutStore.updateRestSecondsRemaining(playsCompletionHaptic:)`,
  gated by a parameter so only the live countdown tick opts in.
- The sound uses a built-in `SystemSoundID` (1016) via
  `AudioServicesPlaySystemSound` rather than a bundled custom audio
  asset — this project isn't set up with Xcode's synchronized-folder
  resource mechanism, and safely registering a new bundle resource in
  `project.pbxproj` by hand (or installing tooling to do it) wasn't
  justified for this. Revisit with a proper custom chime if the project
  migrates to that mechanism, or the `xcodeproj` gem becomes installable
  in the dev environment. Tracked as a backlog item.
- `WorkoutSessionView` sets `UIApplication.shared.isIdleTimerDisabled =
  true` on appear and `false` on disappear. Scoped to that one screen
  only; no other screen needs this.
