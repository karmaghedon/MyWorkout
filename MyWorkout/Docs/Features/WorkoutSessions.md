# Workout Sessions

## Purpose

The workout-session feature manages an in-progress workout safely across navigation and app lifecycle interruptions.

## Main responsibilities

- start a workout
- prevent accidental active-session replacement
- track elapsed time
- log sets
- display previous performance
- generate warm-ups
- run rest timers, suppressed between superset members (see below)
- capture exercise notes
- finish or cancel
- persist and restore active state

## Main types

- `ActiveWorkoutStore`
- `Workout`
- `ExerciseSessionState`
- `RestTimerState`
- `WorkoutSessionEngine`
- `ActiveWorkoutSnapshot`
- `ActiveWorkoutPersisting`
- `WorkoutSessionLayout` — Classic or Checklist, a user setting

## Layout

Two interchangeable presentations of the same exercise/set data, chosen
in Settings → Workout Session (default: Classic):

- **Classic** — `ExerciseSessionCardView`, always-visible weight/reps
  steppers (`CurrentSetCardView`).
- **Checklist** — `ChecklistExerciseSessionCardView`, warm-up and
  working sets as tappable `SetChecklistRow`s; the next working set has
  two always-visible, directly-tappable numeric fields
  (`NumericPadTextField`) for weight and reps instead of needing a
  pencil tap to reveal a stepper first.

Both read from and write to the same `ExerciseSessionState`, so
switching layouts mid-workout loses nothing.

Tapping an exercise's name on either layout's session card opens its
full `ExerciseDetailView` in a sheet — the same detail screen the
Exercise Library uses, for looking up how to perform it without leaving
the workout.

`BarbellPlateView`'s suggested-plates graphic runs ~25% larger
(min/max plate height 16→20/34→42, width 10→13, label 8pt→9pt) than its
original size, per feedback that the plates were hard to read at a
glance mid-set.

## Warm-ups

`WarmupEngine.generateWarmups` produces the default ramp from the
working weight, exercise type, and whether the exercise uses a barbell.
Superset/circuit members (`exercise.supersetGroupID != nil`) skip
warm-ups entirely on both layouts — the assumption is the muscle group
is already warm from the prior exercise in the group.

`WarmupEngine.resolveWarmups` is the single shared entry point both
session card views call to decide what ramp to actually show, with
three-tier precedence: a session-time override
(`ExerciseSessionState.customWarmups`) wins over a template-configured
fixed ramp (`Exercise.customWarmups`, see `Docs/Features/Templates.md`'s
"Auto Warm-up" toggle), which wins over auto-calculation from the
current working weight. This lets a template lock in a dialed-in ramp
as the default while still allowing one-off session edits without
changing the template.

The Checklist layout can override the resolved ramp per session,
without touching the template: each warm-up row is editable (weight and
reps, via its pencil icon), warm-up sets can be added ("Add Warm-up
Set") or removed ("Remove This Set," inside the open editor), and the
override is stored in `ExerciseSessionState.customWarmups` — `nil`
means "defer to the template override or auto-generated ramp," non-`nil`
fully replaces it for that session. Editing/removing a specific row is
matched **by its position** in the list, not by `WarmupSet.id`: the
auto-generated ramp mints a fresh random id every time it's recomputed,
so position is the only stable identity until the list has actually
been materialized into `customWarmups`.

The Checklist layout's warm-up section is a `DisclosureGroup` that
auto-collapses itself (but remains manually re-expandable) the moment
every warm-up row in it is checked off — before that, a tall warm-up
list can push the exercise's own name/set-count header off the top of
the screen once the view scrolls to center the first working set or
the rest timer; collapsing it as soon as it's no longer needed keeps
the header on screen for the working sets that follow. See "Header
visibility" below for the rest of that fix.

Working sets have the mirror capability for a session-only extra set —
`ActiveWorkoutStore.addExtraSet`/`removeExtraSet` adjust
`ExerciseSessionState.extraWorkingSets` on top of the template's
`Exercise.targetSets`. The Checklist layout's "Remove Set" button next
to "Add Set" only appears once the extra slot is actually the one
showing as "next" (i.e. the template's own default sets are already
logged) — tapping "Add Set" always counts immediately, but there's
nothing visible yet to remove until then.

## Supersets

Exercises sharing a template-configured `Exercise.supersetGroupID` are
meant to be performed back-to-back with no rest between them, resting
only once the group's last member (by the workout's exercise order)
logs a set. `WorkoutSessionEngine.shouldStartRest(after:in:)` decides
this per set logged — ungrouped exercises always start rest, unchanged.
Session cards for grouped exercises render a colored leading bar so the
grouping is visible while actually working out, matching the same
treatment shown when building the template.

In the Checklist layout, the rest timer renders inline within the
working-set list — right after the row for the set that just triggered
it, before whatever comes next (the next working-set row, or the "Add
Set" button if that was the last one) — rather than trailing the whole
card.

## Rest-timer scroll centering

`WorkoutSessionContentView.scrollTarget` decides where the session
screen auto-scrolls to (the resting exercise's badge, a superset
partner waiting on you, or wherever you last logged a set). Two bugs
here were fixed together, since they shared one cause:

- Rest ending on any exercise used to jump the view to an unrelated
  superset elsewhere mid-rotation — that "blocked, waiting on partner"
  state persists for most of the time between a superset's own rounds,
  and the check for it scanned the *whole* workout rather than being
  scoped to whatever you were actually just working on. Fixed by
  scoping it to `ActiveWorkoutStore.lastLoggedExerciseID`, set whenever
  `logSet(for:)` runs.
- `WorkoutSessionEngine.restTimerAnchorExerciseID` always anchored the
  rest badge to the group's *positionally* first member, even after
  that member had finished all its own sets — so once one superset
  member has more sets configured than the other, the badge stayed
  stuck on a card you were done with for the remainder of that
  exercise. Fixed to anchor on the first still-*active* member instead
  (falls back to whichever exercise triggered the rest if every member
  has finished).

## Header visibility

Each session card can be much taller than the screen (warm-ups, several
logged sets, notes), so scrolling to center the *whole card* routinely
left `ExerciseSessionHeaderView` — the only place showing the exercise
name and set progress together — scrolled off the top of the screen
once a set was logged or rest started. Two changes fix this together:

- `ExerciseSessionHeaderView.scrollAnchorID(for:)` gives the header
  itself a stable scroll-anchor id, separate from the card's own id —
  same precedent as `RestTimerBadge.scrollAnchorID`. The three
  non-rest-timer branches of `WorkoutSessionContentView.scrollTarget`
  (a superset partner waiting on you, or wherever you last logged a
  set) scroll to this header id with `anchor: .top` instead of to the
  card with `anchor: .center`.
- The rest-timer branch still anchors on `RestTimerBadge.scrollAnchorID`
  (unchanged — see "Rest-timer scroll centering" above), which is the
  most common trigger since nearly every logged set starts a rest
  period. Anchoring the *badge* rather than the header there is
  intentional — the badge is what you actually need to see mid-rest —
  but a long warm-up list above it could still push the header out of
  view by the time rest ends. The Checklist layout's warm-up
  auto-collapse (see "Warm-ups" above) addresses that by shortening the
  card once warm-ups are no longer relevant, rather than by changing
  this anchor.

## Set progress display

`ExerciseSessionHeaderView` shows a `Set loggedSetCount/targetSetCount`
chip (e.g. "Set 3/4") next to the exercise name, via
`WorkoutSessionEngine.targetSetCount(for:state:)` — the template's
`Exercise.targetSets` plus any session-only extra sets
(`ExerciseSessionState.extraWorkingSets`), floored at the number
actually logged so far in case that ever exceeds the configured target.
Both layouts compute this the same way and pass it into the shared
header view.

## Rest timer sound

`RestTimerSound` (`UserSettings`) — a user-configurable sound to play
alongside the completion haptic when the rest timer finishes, set in
Settings → "Rest Timer Sound" (each option has a preview button).
`ActiveWorkoutStore` receives the current selection the same way it
already receives `RestTimerRule`'s settings — threaded in via
`startRestTimer(for:settings:)`, no standing settings dependency needed
on the store itself.

Three options play a built-in iOS system alert tone by numeric ID
(`Haptics.swift`, `AudioServicesPlaySystemSound`) — the *real named*
modern alert tones (the ones in iOS's own Settings app, e.g. "Radar")
turned out to be unreachable, since their files live under a system
path this app's sandbox can't read on current iOS. The fourth option,
Silver Bell, is synthesized entirely from scratch instead
(`BellSynthesizer`) — additive synthesis with inharmonic overtone
ratios and independent per-partial exponential decay, the way a real
small bell actually rings, rendered via `AVAudioEngine`/
`AVAudioPCMBuffer` and struck three times back-to-back so it's long
enough to actually notice.

## UI composition

`WorkoutSessionView` assembles reusable session components including:

- pinned workout timer (`CompactWorkoutTimerBar`)
- exercise list (`WorkoutExerciseListView`, branches per exercise on
  `WorkoutSessionLayout` and applies the superset leading-bar indicator)
- session card (Classic or Checklist, see above)
- current set card / checklist rows
- warm-up section
- previous performance
- logged sets
- notes
- action controls
- dialogs

## Persistence behavior

The active workout persists independently from workout history.

Navigation away from the session must not reset:

- workout start time
- elapsed duration
- logged sets
- notes
- rest timer

## Starting another workout

When an active workout exists, a new workout must not silently overwrite it.

The start flow should return an explicit result that allows the UI to resume the existing session or present an appropriate restriction.

## Finish behavior

Finishing creates a `WorkoutLog`, saves it through `WorkoutLogStore`, and clears active persistence.

## Cancel behavior

Canceling clears current session state and removes the persisted active snapshot.

## Regression focus

- start
- second-start prevention
- restore
- duration
- rest timer, including that it's suppressed between superset members,
  only starts for the group's last exercise, and (Checklist) renders
  inline after the triggering set rather than trailing the card
- set state
- cancel
- finish
- persistence failure
- delete failure
- Classic/Checklist layout switch mid-workout
- warm-ups suppressed for superset members on both layouts
- Checklist warm-up edit/add/remove, matched by position rather than id
- "Remove Set" only appears once the extra working set is genuinely
  visible on screen
- `WarmupEngine.resolveWarmups` precedence: session override beats
  template override beats auto-calculation
- Checklist warm-up section auto-collapses once every row is checked,
  and can still be manually re-expanded afterward
- header stays visible (anchored via `scrollAnchorID`, `.top`) when
  scrolling to a superset partner or the last-logged exercise
- `Set N/M` header chip reflects extra session-only sets and floors at
  the actual logged count
