Version: 2.0
Last Updated: 2026-08-19
Status: Active

Phases are checked off as their work lands on `remodeling`, not when
they're merely planned.

This roadmap previously listed 12 narrow phases (F1-F7 navigation/design-
system work, then F8-F12 splitting "polish" into Components, Micro
Interactions, Accessibility, Performance, and Final Polish). That
structure has been retired in favor of matching
`MyWorkout Design Blueprint_F1.1.md`'s 8-phase scope, which is now this
project's authoritative frontend phase definition — the Blueprint's F3-F7
are considerably richer than this document's old versions of the same
numbers (e.g. old-F4 was just "Templates reachable from the Workout tab";
Blueprint-F4 is the full workout experience: template cards, session
progress, finish summary, exercise flow, workout insights). A phase is
only checked below once every sub-goal the Blueprint lists for it is
actually built, not when the first slice of it lands — partial progress
is called out per phase instead.

F1 — Navigation

☑

Tab shell, five independent NavigationStacks, shared tab bar, stateful
Workout destination. Fully done — see `NavigationArchitecture_F1.1.md`
and `FrontendDecisionLog_F1.1_Entries.md` FDL-001 through FDL-004.

F2 — Design System

☑

17 components in `Features/Shared/Components/`, all reading `AppTheme`
tokens (color, typography, spacing, radius, elevation, motion). Fully
done — see `ComponentLibrary_F1.0.md` and `DesignSystem_F1.0.md`.

F3 — Home

☑ (all sub-goals implemented; not yet device-tested — see
`PendingDeviceTests.md`)

- [x] Welcome — greeting header, time-of-day aware.
- [x] Resume Workout — stateful hero card (start / resume).
- [x] Today's Progress — new "Today" card between the hero and the
      lifetime Overview stats: workouts and sets logged today, counting
      an active workout that started today alongside completed logs.
- [x] Recovery — Home now surfaces the most severe recovery warning (if
      any), with a count of additional warnings and a link into
      Analytics. Hidden entirely when there are none.
- [x] Weekly Summary — new "This Week" card: workout/set totals for the
      current calendar week plus a 7-day strip showing which days had
      a workout.
- [x] PR Highlights — new "New Personal Records" card, shown when a set
      logged today ties/beats an all-time personal record. Not yet
      device-tested — see `PendingDeviceTests.md`.
- [x] Next Workout — new "Next Up" card suggesting the
      least-recently-performed template, with a one-tap start button.
      Hidden while a workout is already active. Not yet device-tested.

F4 — Workout

☑ (all sub-goals implemented; not yet device-tested — see
`PendingDeviceTests.md`)

- [x] Template Cards — `StartWorkoutView`'s template rows (`WorkoutCard`).
- [x] Workout Dashboard — `StartWorkoutView` serves as the hub; templates
      are now also reachable for management, not just starting (F4 nav
      work, prior version of this roadmap).
- [x] Session Progress — `WorkoutSessionView`'s timer, current-set card,
      logged sets, rest timer.
- [x] Finish Summary — new `WorkoutFinishSummaryView`, a full-screen
      cover shown after the existing "Finish Workout?" confirmation
      saves the log: duration, exercises, sets, and a volume-vs-last-time
      comparison.
- [x] Exercise Flow — `ExerciseSessionCardView`'s warmups, current set,
      logged sets, notes.
- [x] Workout Insights — the same Finish Summary screen calls out any
      new personal records set specifically by that session.

F5 — Library

☐ (least mature phase)

- [ ] Rich Exercise Cards — `ExerciseRowView` (the list row) is a plain
      name/subtitle row; `ExerciseDetailView` itself is already rich
      (header, badges, muscles, instructions, tips, warnings) but the
      browse experience isn't.
- [ ] Filters — none. The list is grouped by muscle group only.
- [ ] Muscle Chips — muscle info shows as plain text in list rows and as
      `InfoBadge` in detail; not used as a browsable/filterable facet.
- [ ] Equipment — shown as text/badge, not filterable.
- [ ] Difficulty — shown in detail, not filterable.
- [ ] Favorites — not built.
- [ ] Related Exercises — not built.
- [x] Custom Exercises — reachable and manageable from the Library tab
      (F5 nav work, prior version of this roadmap).

F6 — Progress

☐ (partial, core analytics solid)

- [x] Strength Trends — `StrengthTrendView`.
- [ ] Volume Trends — `VolumeByMuscleGroupSection` shows current totals
      per muscle group, not a trend over time.
- [x] Muscle Distribution — effectively covered by
      `VolumeByMuscleGroupSection`.
- [x] Personal Records — `PersonalRecordsSection`.
- [ ] Consistency — no streak/consistency tracking exists anywhere in
      the codebase.
- [x] Recovery — `RecoveryWarningsSection`.
- [ ] Future Body Metrics — not built; listed under "Deferred product
      ideas" in `Docs/Development/DevelopmentRoadmap.md`, so likely out
      of scope until that's revisited.

F7 — Profile

☐ (nearly done)

- [x] Settings — `ProfileHubView` → `SettingsView`.
- [x] Equipment — `ProfileHubView` → `EquipmentInventoryView`.
- [x] Units — part of Settings.
- [x] Backup — `ProfileHubView` → `ExportView` ("Backup & Data").
- [x] Restore — import, part of Backup & Data.
- [ ] About — no About screen exists (version, credits, support info).

F8 — Premium Polish

☐

- [ ] Haptics — partial: rest-timer completion and set-logged feedback
      exist (`Haptics.swift`); not audited beyond those two triggers.
- [ ] Micro Animations — partial: `AppTheme.Motion` tokens exist and are
      used in a few places (rest timer badge, card transitions); not a
      deliberate pass across every interaction.
- [ ] Accessibility Audit — substantial cross-screen work already done
      (design tokens, touch targets, VoiceOver labeling on decorative
      icons — see FDL-014) but not the formal, exhaustive pass this item
      implies (Dynamic Type at accessibility sizes, full VoiceOver
      navigation-order testing, Reduce Motion). Groundwork, not complete.
- [ ] Performance Audit — not done.
- [ ] Skeleton Loading — `LoadingState` component exists but has no
      consumer; the app is fully local/synchronous today so nothing
      currently needs one.
- [ ] Transition Polish — not specifically addressed.
- [ ] Final UI Review — not done.
