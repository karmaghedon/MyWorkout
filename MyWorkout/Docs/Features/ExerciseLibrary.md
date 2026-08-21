# Exercise Library

## Purpose

The exercise library is both a selection source for workouts and the foundation of the exercise encyclopedia.

## Exercise information

An exercise may include:

- identity and name
- equipment
- exercise type
- difficulty
- primary muscles
- secondary muscles
- instructions
- coaching tips
- common mistakes
- safety warnings
- progression rule
- progression strategy
- per-template overrides: working-set count, starting weight, superset
  group (see `Docs/Features/Templates.md` — these live on `Exercise`
  but only apply to the copy of it stored inside a given
  `WorkoutTemplate`, not the catalog entry itself)

The seed catalog (`SeedData.swift`) grew from its original 17 exercises
to 42 (barbell, dumbbell, bodyweight, and resistance-band movements
across every muscle group), each researched and added with the fuller
detail fields (primary/secondary muscles, tips, common mistakes,
warnings) populated — the original 17 predate that convention and
mostly leave those fields empty. `Hammer Curl` was later backfilled
with the same fuller detail as a one-off correction, but the rest of
the original 17 remain untouched; filling them in the same way is
open, low-risk future work, not a bug.

## Capabilities

- browse grouped by muscle group, with a "show more" cutoff per group
- filter by equipment, difficulty, and favorites-only
- favorite/unfavorite an exercise (`FavoriteExercisesStore`), persisted
  by normalized exercise name rather than `Exercise.id` — a built-in
  exercise's id is now stable across launches (see Identity
  compatibility below), but this store was written before that fix and
  has had no reason to migrate off name-keying since
- exercise detail view: overview, muscles, instructions, tips, warnings

Not yet implemented: searching the Library by name. A search field
exists for the *template* exercise pickers
(`CreateWorkoutTemplateView`, `TemplateExercisePickerView`) but hasn't
been added to `ExerciseLibraryView` itself — same
`.localizedCaseInsensitiveContains` pattern would apply directly if
added.

## Sources

Exercises may come from:

- built-in seed data
- user-created custom exercises
- template references
- historical workout references

## Registry

`ExerciseRegistry` centralizes lookup across these sources.

Features should not create independent name-only lookup implementations.

## Main views

- `ExerciseLibraryView`
- `ExerciseRowView`
- `ExerciseDetailView`
- `ExerciseHeaderView`

Reusable detail components include:

- `ExerciseOverviewView`
- `ExerciseMusclesView`
- `ExerciseInstructionsView`
- `ExerciseTipsView`
- `ExerciseWarningsView`

## Identity compatibility

Current records prefer stable exercise identifiers.

Historical logs that predate identifiers may fall back to exercise-name matching.

This fallback must remain limited to backward compatibility.

### Built-in exercise ids are deterministic, not random

A built-in exercise's `id` is derived from its name —
`SHA256(name.utf8).prefix(16 bytes)` interpreted directly as a `UUID`
(`SeedData.stableID(for:)`) — not `Exercise.init`'s default `UUID()`.
This was a real, previously-shipped bug: without it, every built-in
exercise got a *fresh random* id on every app launch (custom exercises
were unaffected — they persist a real UUID once created), which
silently fragmented that exercise's favorite/PR/analytics history each
time the app restarted, since `exerciseID` comparisons never matched
across launches.

This matters beyond the original bug fix: any external data that needs
to line up with the live app's exercise identity (a backup import, a
migration script) must reproduce this exact same hash — matching by
name string alone is not sufficient once real logged history exists,
because `AnalyticsEngine`/`WorkoutSessionEngine`'s grouping key is
`exerciseID?.uuidString ?? exerciseName`, and a `nil`-id entry falls
into a different bucket than a same-exercise entry that does have the
id populated. A Python reproduction of the same hash
(`uuid.UUID(bytes=hashlib.sha256(name.encode()).digest()[:16])`) was
verified byte-for-byte against the real Swift output before being used
to convert an external workout history export into this app's backup
format.

## Future extensions

Potential additions:

- search (see Capabilities above — not yet on the Library root, though
  the pattern already exists elsewhere in the app)
- images
- videos
- muscle diagrams
- alternatives
- variations
- per-exercise history
- education depth by experience level
- fill in primary/secondary muscles, tips, common mistakes, and
  warnings for the original 17 seed exercises that predate that
  convention (see Exercise information above)
