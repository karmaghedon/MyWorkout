# Frontend Decision Log — F1.1 Entries

**Version:** 1.2  
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
