Version: 2.1
Last Updated: 2026-08-21
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

☑ device-tested

- [x] Welcome — greeting header, time-of-day aware.
- [x] Resume Workout — stateful hero card (start / resume).
- [x] Today's Progress — new "Today" card between the hero and the
      lifetime Overview stats: workouts and sets logged today, counting
      an active workout that started today alongside completed logs.
      **Known limitation:** an active session is counted toward "today"
      by when it *started*, not when each set was logged — a workout
      started at 11:50pm whose sets get logged after midnight won't
      count toward the new day until it's finished. Fixing this properly
      needs a per-`LoggedSet` timestamp, which doesn't exist yet;
      flagged rather than fixed since it's a narrow edge case.
- [x] Recovery — Home now surfaces the most severe recovery warning (if
      any), with a count of additional warnings and a link into
      Analytics. Hidden entirely when there are none.
- [x] Weekly Summary — new "This Week" card: workout/set totals for the
      current calendar week plus a 7-day strip showing which days had
      a workout.
- [x] PR Highlights — new "New Personal Records" card, shown when a set
      logged today genuinely beats (not ties) the prior best for that
      exercise — reuses `WorkoutSessionEngine.newPersonalRecords`, the
      same comparison the Finish Summary screen uses, so the two can't
      disagree.
- [x] Next Workout — new "Next Up" card suggesting the
      least-recently-performed template, with a one-tap start button.
      Hidden while a workout is already active. **Known limitation:**
      matches workout history to a template by name
      (`WorkoutLog.workoutName == template.name`) — renaming a template
      orphans its prior history from the match, making a
      just-performed-then-renamed template look never-performed (most
      overdue). Fixing this needs a `templateID` captured on `WorkoutLog`
      at finish time, threaded through `Workout` itself, which doesn't
      currently carry one; flagged rather than fixed since it's a narrow
      edge case (renaming a template right after using it).

F4 — Workout

☑ device-tested

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

☑ device-tested

- [x] Rich Exercise Cards — `ExerciseRowView` redesigned with an
      equipment icon badge and muscle/equipment/difficulty `Chip`s
      instead of a plain joined-text subtitle.
- [x] Filters — toolbar filter menu on `ExerciseLibraryView`: Equipment,
      Difficulty (options derived from the actual exercise data), and
      Favorites Only.
- [x] Muscle Chips — muscle group now renders as a `Chip` on every row
      (see Rich Exercise Cards).
- [x] Equipment — filterable via the filter menu; shown as a `Chip` and
      an icon badge on rows.
- [x] Difficulty — filterable via the filter menu; shown as a `Chip`.
- [x] Favorites — new `FavoriteExercisesStore`; star toggle per row.
- [x] Related Exercises — `ExerciseDetailView` shows up to four other
      exercises sharing the same muscle group.
- [x] Custom Exercises — reachable and manageable from the Library tab
      (F5 nav work, prior version of this roadmap).

F6 — Progress

☑ device-tested (Future Body Metrics excluded — deferred elsewhere)

- [x] Strength Trends — `StrengthTrendView`.
- [x] Volume Trends — new `VolumeTrendSection`: weekly total volume
      over the last 12 weeks with data, as a bar chart.
- [x] Muscle Distribution — covered by `VolumeByMuscleGroupSection`.
- [x] Personal Records — `PersonalRecordsSection`.
- [x] Consistency — new `ConsistencySection`: current streak (weeks in
      a row with a workout) plus a 12-week activity strip.
- [x] Recovery — `RecoveryWarningsSection`.
- [ ] Future Body Metrics — not built; listed under "Deferred product
      ideas" in `Docs/Development/DevelopmentRoadmap.md`, so likely out
      of scope until that's revisited.

F7 — Profile

☑ device-tested

- [x] Settings — `ProfileHubView` → `SettingsView`.
- [x] Equipment — `ProfileHubView` → `EquipmentInventoryView`.
- [x] Units — part of Settings.
- [x] Backup — `ProfileHubView` → `ExportView` ("Backup & Data").
- [x] Restore — import, part of Backup & Data.
- [x] About — new `AboutView` (name, version/build, short description),
      reachable from a new "About" section on `ProfileHubView`.

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

Additional Work — Workout Session Redesign

☑ device-tested

Outside the Blueprint's original 8 phases — a separate, later initiative
covering the Workout session screen specifically. See FDL-020 for the
full decision record, and FDL-023 for two on-device-reported corrections
(warm-up rows checking together, no way to adjust weight before
logging — both fixed).

- [x] Settings toggle (`WorkoutSessionLayout`: Classic / Checklist,
      defaults to Classic) under Settings → Workout Session.
- [x] Pinned workout timer (`CompactWorkoutTimerBar`) above the scrolling
      exercise list, on both layouts.
- [x] Checklist layout — warm-up and working sets as tappable checklist
      rows (`ChecklistExerciseSessionCardView`, `SetChecklistRow`)
      instead of Classic's stepper.
- [x] Template-defined working-set count (`Exercise.targetSets`,
      configurable 1–10 per exercise in template creation/editing) plus
      a session-time "Add Set" affordance.

Additional Work — Template Editing: Search, Starting Weight, Supersets

☑ device-tested

A second, later initiative on top of the one above — Create/Edit
Template and the exercises they build. See FDL-021, FDL-022, FDL-024,
and FDL-026 for the full decision records.

- [x] Search field on both exercise pickers (`CreateWorkoutTemplateView`,
      `TemplateExercisePickerView`), alongside the existing equipment
      filter.
- [x] Per-exercise starting-weight override (`Exercise.targetWeightPounds`)
      configurable in template creation/editing, only used the first
      time an exercise is performed — progression history takes over
      after that.
- [x] `WorkoutTemplateStore.syncStartingWeights(from:)` keeps that
      displayed value honest after real history exists, updating it to
      the last logged set after every finished workout.
- [x] Superset/circuit grouping (`Exercise.supersetGroupID`) — group 2+
      exercises via a "Group" mode in the shared `TemplateExercisesSection`
      component; grouped exercises rest only after the group's last
      member logs a set (`WorkoutSessionEngine.shouldStartRest`).
- [x] `CreateWorkoutTemplateView` rebuilt onto `TemplateEditorView`'s
      `Form`-based structure, and both screens now share
      `TemplateExercisesSection` instead of duplicating the
      sets/weight/grouping UI — closes off the drift-between-two-screens
      risk that caused two of this phase's own bugs (FDL-021).

Additional Work — Data Integrity & Platform Fixes

Fixed, not a feature — grouped here since none of these map to a single
Blueprint phase. See FDL-022, FDL-025, and FDL-027.

- [x] `WorkoutTemplateStore.refreshed` no longer silently discards a
      template's `targetSets`/`targetWeightPounds`/`supersetGroupID` on
      every save (FDL-022).
- [x] `WorkoutLogStore` now enforces its own newest-first ordering
      invariant in `replaceAll`/`load` instead of trusting caller order
      — a real bug that made the app suggest a long-past first-ever
      weight instead of the most recent one after a chronologically-
      ordered backup import (FDL-025).
- [x] Custom tab bar no longer gets pushed up by the keyboard, covering
      whatever field was being edited (FDL-027).
- [x] App launch icon — `AppIcon.appiconset` previously had only unused
      macOS-idiom entries with no backing image; replaced with the
      modern single-size iOS format.
