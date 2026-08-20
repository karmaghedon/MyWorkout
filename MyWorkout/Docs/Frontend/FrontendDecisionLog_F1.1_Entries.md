# Frontend Decision Log — F1.1 Entries

**Version:** 1.8  
**Date:** 2026-08-20  
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

---

## FDL-016 — Implement F4-F7: give every screen a tab-owned route, not just a Home shortcut

**Decision**
Wire the six destinations `NavigationArchitecture_F1.1.md` assigns to
Workout, Library, Progress, and Profile — Templates, Custom Exercises,
Analytics, Strength Trends, Equipment, and Backup & Data — into their
owning tabs, and remove them from Home now that they no longer need a
placeholder home there. Concretely: a "Manage Templates" toolbar link
from `StartWorkoutView` (F4); a "Custom Exercises" toolbar link from
`ExerciseLibraryView` (F5); a new `ProgressHubView` tab root organizing
History/Analytics/Strength (F6); a new `ProfileHubView` tab root
organizing Settings/Equipment/Backup & Data (F7).

**Reason**
`NavigationArchitecture_F1.1.md` (written before F1 even landed) already
specified this ownership. FDL-013 called it out explicitly as a known
gap: Home kept these four Manage-section destinations as a "deliberate
placeholder, not a final decision," waiting on exactly F5 and F7. Doing
all four phases together (rather than one at a time) let Home's cleanup
happen in the same pass its last placeholder link was removed, instead
of leaving Home in a half-cleaned state between phases.

**Consequences**
- `ProgressHubView` and `ProfileHubView` are new tab roots, both reusing
  a new shared `QuickActionSection` component (a titled card of
  `QuickActionRow` links) — extracted from `DashboardView`'s
  `dashboardSection`, which had the identical shape before its Manage/
  Progress sections were removed.
- No `AppRoute` cases changed. Every destination (`.templates`,
  `.customExercises`, `.analytics`, `.strengthTrends`, `.equipmentInventory`,
  `.export`, `.settings`, `.history`) was already registered in
  `AppShellView`'s shared route resolver; this work only added new
  places that push to those existing routes.
- `DashboardView` lost its "Progress" and "Manage" sections and the
  now-dead `dashboardSection`/`quickActionLink` helpers that built them.
  Home is now exactly what `NavigationArchitecture_F1.1.md` specifies:
  greeting, active-workout/start hero, stats, recent activity — no
  destination duplicated with a permanent tab.
- One documented target from `NavigationArchitecture_F1.1.md`'s Library
  section is knowingly still unmet: custom exercise creation
  (`AppRoute.createCustomExercise`) remains a push destination, not the
  sheet the doc recommends. Fixing it would mean moving `CustomExercisesView`
  off the shared `AppRoute`-push pattern for creation specifically (onto
  a local `@State` + `.sheet`, the same shape `TemplatesView` already
  uses for `CreateWorkoutTemplateView`) without touching how editing is
  reached, which stays a push. Left as a tracked follow-up rather than
  bundled into this pass — the feature is fully functional as a push,
  this is a presentation-style refinement, not a gap in reachability.
- History and Settings are now one level deeper than before F6/F7 (pushed
  from their hub, not the tab's direct root) — a deliberate trade of one
  extra tap for the hub screen's stated purpose of surfacing progress/
  profile options that were previously invisible outside Home.

---

## FDL-017 — Adopt the Design Blueprint's phase scope as authoritative; retire the 12-phase roadmap structure

**Decision**
`FrontendRoadmap_F1.0.md` previously defined 12 narrow phases, where
F4-F7 meant specifically "give this destination a tab-owned route" (see
FDL-016) and F8-F12 split "polish" into five separate small phases
(Components, Micro Interactions, Accessibility, Performance, Final
Polish). Replace that structure with `MyWorkout Design Blueprint_F1.1.md`'s
8-phase scope, where the same F3-F7 numbers mean the full feature vision
for each destination (e.g. Blueprint-F5 "Library" includes filters,
favorites, and related exercises — not just "Custom Exercises is
reachable"), and F8 "Premium Polish" is a single phase bundling
everything the old F8-F12 split apart. Un-check F3-F7 on the roadmap and
replace their single checkbox with an itemized per-goal list showing
exactly what's built versus not, rather than leaving them showing
"done" against a scope they don't actually cover.

**Reason**
Both documents used identical phase numbers (F1-F7) for substantially
different scope, discovered when asked to survey "the rest of the
roadmap" (F8-F12) after F4-F7 had just been marked done — under the
Blueprint's definition, none of F3-F7 are actually complete. Leaving two
roadmap documents disagreeing under the same phase numbers is worse than
either being wrong alone: a reader consulting one document would
reasonably believe a phase is finished when the other says otherwise, and
neither document flagged the conflict. The user chose the Blueprint as
authoritative — it's the more detailed and evidently more current
product vision (the Home Blueprint's own F3 goals — recovery signals, PR
highlights, next-workout preview — go well beyond what shipped in
FDL-013's Home redesign).

**Consequences**
- `FrontendRoadmap_F1.0.md` is now structurally identical to the
  Blueprint's phase list (F1-F8, not F1-F12). Version bumped 1.2 → 2.0
  to signal the structural change, not just a content update.
- F1 and F2 remain checked — both documents already agreed those were
  fully done, and verification confirmed it (tab shell, 17-component
  design-token library).
- F3-F7 are now itemized per Blueprint sub-goal rather than single
  checkboxes, so future work can check off individual items (e.g. "PR
  Highlights" on Home) without needing every other item in that phase
  finished first to show any progress at all.
- The real, valuable work already done under the old F4-F7 definition
  (Templates/Custom Exercises/Analytics/Strength/Equipment/Backup &
  Data all reachable from their owning tab) isn't lost — it's now
  correctly represented as partial progress within the broader Blueprint
  phases (e.g. "Custom Exercises" checked under F5, alongside unchecked
  "Filters," "Favorites," "Related Exercises").
- What's actually missing across F3-F8 is substantial, closer to new
  feature work than the wiring-level F4-F7 navigation pass was:  Home
  needs recovery/weekly-summary/PR-highlight/next-workout content;
  Workout needs a real Finish Summary and post-workout insights; Library
  needs filters, favorites, and related exercises — its least-built
  phase; Progress needs volume trends over time and consistency
  tracking; Profile needs an About screen; Premium Polish needs a
  performance pass and an exhaustive (not just substantial) accessibility
  review. None of this was implemented as part of this decision — see
  `FrontendRoadmap_F1.0.md` for the itemized list and prioritize from
  there.

---

## FDL-018 — F3-F7 implemented and device-verified

**Decision**
Implement every sub-goal FDL-017 identified as missing across F3-F7 —
Today's Progress, Recovery, Weekly Summary, PR Highlights, and Next
Workout on Home (F3); a Finish Summary screen with Workout Insights
(F4); rich exercise cards, filters, favorites, and related exercises in
the Library (F5); Volume Trend and Consistency in Analytics (F6); an
About screen in Profile (F7) — then verify all of it on the physical
device rather than treating a successful build as sufficient.

**Reason**
A `xcodebuild` success only confirms the code compiles; several of these
features involve interaction patterns (a favorite-star button sitting
beside, not inside, a `NavigationLink`'s label; a full-screen cover
replacing an immediate dismiss on workout finish; filter state actually
narrowing a grouped list) that can only be confirmed correct by actually
tapping through them. A temporary `PendingDeviceTests.md` tracked exactly
what to check per feature while the device was unreachable; every item
passed once it was reconnected, and that file has been deleted per its
own note to do so once everything was checked off.

**Consequences**
- F3 through F7 are now checked "device-tested" on
  `FrontendRoadmap_F1.0.md`, not just "implemented" — the roadmap's own
  standing rule (checked only once actually landed and working, not
  merely compiled) now applies at the sub-goal level introduced by
  FDL-017, not just the phase level.
- New domain surface added along the way: `FavoriteExercisesStore`
  (Domain/Exercise/Stores), and two new personal-record/volume
  computations on `WorkoutSessionEngine` deliberately independent of
  `AnalyticsCache` (which recomputes on a 300ms debounce and would show
  stale data if read immediately after finishing a workout).
- Only F8 (Premium Polish) remains on the roadmap. It's intentionally
  still last — a final polish/audit pass reads best against a feature
  set that's actually finished, which F3-F7 now are.

---

## FDL-019 — Fix built-in exercise identity churn (Favorites, Personal Records)

**Decision**
Stop keying exercise identity by `Exercise.id`/`CompletedExercise.exerciseID`
for any comparison that has to hold across app launches, and use
`ExerciseNameValidator.normalize(name)` instead — in
`AnalyticsEngine.personalRecords`, `WorkoutSessionEngine.newPersonalRecords`,
and `FavoriteExercisesStore` (which switches from persisting `Set<UUID>`
to `Set<String>` of normalized names). Also fix `DashboardView`'s "New
Personal Records" card to reuse `WorkoutSessionEngine.newPersonalRecords`
instead of a second, slightly different hand-rolled comparison; switch its
trophy icon and the Library favorite-star's filled color from raw
`.yellow` off `AppTheme`; and sort the Library difficulty filter by
Beginner → Intermediate → Advanced instead of alphabetically.

**Reason**
An external code-review of this branch's F3-F7 commits (`507f397..93ab086`)
found that `SeedData`'s exercise factory never passes `id:` to `Exercise.init`,
so built-in exercises get a fresh random `id` every app launch — and
`ExerciseRegistry.exercise(id:name:)` already has an ID-then-name fallback
specifically because of this, but nothing else in the codebase used it.
Verifying the report surfaced a larger blast radius than the review itself
scoped: `AnalyticsEngine.personalRecords` and
`WorkoutSessionEngine.newPersonalRecords` also grouped by
`exerciseID?.uuidString ?? exerciseName`, and since `exerciseID` is
populated from that session's live `Exercise.id` on essentially every
real logged set, the `?? exerciseName` fallback almost never actually
fires — meaning a built-in exercise's logged history silently fragmented
into a separate "exercise" every single app launch, not just in the two
sites (`FavoriteExercisesStore`, `DashboardView`) the review flagged.
That's the source feeding `AnalyticsCache.personalRecords`, so
`PersonalRecordsSection` on the Analytics tab was affected too, not only
Home's new card.

**Consequences**
- `ExerciseNameValidator.normalize(_:)` (already public, already the
  function enforcing name uniqueness across built-in and custom
  exercises at creation time) is now the shared stable identity key for
  all three fixed call sites, rather than introducing a new type — it
  already did exactly this job.
- `FavoriteExercisesStore` persists under a new UserDefaults key
  (`favorite_exercise_keys`, not `favorite_exercise_ids`); any
  already-persisted favorites from before this fix are not migrated —
  they were already silently lost on every relaunch before this fix, so
  there's nothing worth preserving.
- Two related findings from the same review — "Next Up" matching
  `WorkoutLog.workoutName == template.name` (breaks if a template is
  renamed) and "Today's Progress" counting an active session by its
  start time rather than each set's own timestamp (undercounts a
  session that crosses midnight) — are deliberately *not* fixed here.
  Both would need new fields threaded through `Workout`/`WorkoutLog`/
  `LoggedSet` and their persistence/decode paths, which is a
  disproportionate amount of data-model change for two narrow edge
  cases. Documented as known limitations on `FrontendRoadmap_F1.0.md`
  under F3's Today's Progress / Next Workout entries instead.
- Not run against the automated test suite — this environment's
  CoreSimulator is broken (see the `myworkout-simulator-broken-use-device`
  memory), so verification was static code reading plus the physical
  device, the same constraint every change this session has worked
  under.

---

## FDL-020 — Workout Session redesign: Checklist layout, pinned timer, template-defined set counts

**Decision**
Add a `WorkoutSessionLayout` setting (`classic` / `checklist`, defaulting
to `classic`) under Settings → Workout Session. Both layouts share a new
`CompactWorkoutTimerBar` pinned above the scrolling exercise list via
`LazyVStack`/`Section`/`pinnedViews: [.sectionHeaders]`, replacing the old
full-width `WorkoutTimerCardView` on the session screen (that view is
left in place, unused, rather than deleted in the same change). The new
`checklist` layout renders `ChecklistExerciseSessionCardView` instead of
`ExerciseSessionCardView`: warm-up sets and working sets each render as a
tappable `SetChecklistRow` (checkbox + weight×reps + plate chip) instead
of a single stepper. Warm-up completion is tracked per exercise, keyed by
weight rather than `WarmupSet.id` (that id is a fresh `UUID()` on every
call to `WarmupEngine.generateWarmups`, which runs fresh on every render).
Checking a warm-up row only marks it done and gives a haptic tap — it
never starts a rest timer, checked or unchecked; only logging a working
set does, unchanged from Classic. How many working-set rows a Checklist
card shows is now driven by a new `Exercise.targetSets` field (default 3,
configurable per exercise when creating or editing a template via a
`Stepper`, 1–10) plus a session-scoped `extraWorkingSets` counter
(`ActiveWorkoutStore.addExtraSet`) for the Checklist card's "Add Set"
button — tapping it is a one-off "one more today," not a template edit.

**Reason**
Implements the mockups at the companion Workout Session Redesign
artifact, per an approved implementation plan (v2) that resolved three
open product questions from an earlier draft: (1) working-set count
should come from the template, with a session-time "add a set" escape
hatch, rather than a hardcoded placeholder; (2) warm-up weights should
already reflect progression history — traced end to end
(`WorkoutSessionEngine.initialState` → `ProgressionEngine.suggestion` →
`WarmupEngine.generateWarmups`) and confirmed this was already true, so
no code changed for that point; (3) warm-up completion should never
trigger a rest timer, unlike an earlier draft that proposed a hardcoded
30-second warm-up rest.

`Exercise.targetSets` required special handling because `Exercise`
already had a hand-written `encode(to:)` but a compiler-synthesized
`init(from:)`. Adding a plain stored property would have made the
synthesized decoder require the new key on every decode — and every
`Exercise` already persisted on a device (inside a saved
`WorkoutTemplate`, a custom exercise, an in-progress workout snapshot, an
exported backup) predates the field, so the first launch after shipping
would throw decoding every one of them. `Exercise` now has an explicit,
hand-written `init(from:)` mirroring its `encode(to:)`, using
`decodeIfPresent(...) ?? 3` only for `targetSets` — verified with a test
that encodes a real `Exercise`, strips the key back out to simulate a
pre-change payload, and confirms it decodes rather than throwing
(`ExerciseCodableTests`). `ExerciseSessionState`'s two new fields
(`completedWarmupWeights`, `extraWorkingSets`) already had a
hand-written decoder from an earlier change, so they only needed the
same `decodeIfPresent ?? default` treatment, covered by
`ExerciseSessionStateCodableTests`.

**Consequences**
- `WorkoutTemplate.exercises` holds `Exercise` value copies, not
  references, so the same exercise can carry a different `targetSets` in
  different templates for free — no extra keying by template needed.
- Warm-up completions never enter `WorkoutSessionEngine.workoutLog(...)`
  (it only reads `state.loggedSets`), and working sets logged from the
  Checklist card's "next" row call the same `ActiveWorkoutStore.logSet`
  path Classic's stepper uses — Finish Summary, PR detection, and CSV
  export all behave identically regardless of which layout logged a set,
  and neither `targetSets` nor `extraWorkingSets` ever reach analytics.
- Existing users default to `classic` and see no visual change until they
  opt into Checklist from Settings; existing templates/custom
  exercises/saved workouts all decode with `targetSets == 3`.
- Not yet device-tested — the physical device wasn't reachable when this
  landed (see the `myworkout-simulator-broken-use-device` memory; this
  environment's CoreSimulator can't stand in). Build and
  build-for-testing both succeed. Flagged on `FrontendRoadmap_F1.0.md`
  pending a device pass.
