# Progression

## Purpose

Progression logic recommends a next training load based on the exercise rule and recent performances.

## Main types

- `ProgressionEngine`
- `ProgressionStrategy`
- `ProgressionRule`

## Current strategy

The primary implemented strategy is double progression.

A rule defines values such as:

- minimum reps
- maximum reps
- increase amount
- deload amount
- stall limit

`ProgressionRule` (and `Exercise.progressionRule`) are mutable and
configurable per *template* — same value-copy override pattern as
`targetSets`/`targetWeightPounds`/`supersetGroupID` in
`Docs/Features/Templates.md` — so a template can match how its owner
actually trains (e.g. straight sets of 8) rather than always working up
to the global default `maxReps` before a weight increase is suggested.

## Input

Progression uses:

- the exercise definition
- current completed sets
- recent previous performances

## Output

The engine may recommend:

- maintaining the current weight
- increasing weight
- deloading after repeated failure
- no suggestion when data is insufficient

A "failure" toward a deload means a logged set falling genuinely short —
reps below `minReps` — not merely missing `maxReps` on a set. Comparing
against `maxReps` instead of `minReps` was a bug: it meant any session
that didn't max out every single set (completely normal rep variance)
counted toward a deload, so exercises could lose weight even while the
lifter was holding steady or just short of the top of the rep range.
Both `weightedSuggestion` failure checks (`failedCurrent` and
`previousFailuresSameWeight`) now compare against `minReps`.

## Per-exercise opt-out

`Exercise.progressionEnabled` (default `true`) lets a template turn
automatic progression off entirely for one exercise — same per-template
override pattern as `progressionRule`. When `false`,
`WorkoutSessionEngine.initialState` skips `ProgressionEngine.suggestion`
altogether and carries the last logged weight and rep count forward
unchanged, with no suggestion message. This is for exercises the user
wants to keep in full manual control (e.g. technique-sensitive lifts),
without losing automatic progression elsewhere in the same workout. See
`Docs/Features/Templates.md` for the template-editor toggle
("Auto Progression").

## Store integration

`WorkoutLogStore.suggestedStartingSet` gathers prior performances and delegates the decision to `ProgressionEngine`.

The store owns data retrieval; the engine owns the training rule.

## Design rules

- no persistence inside progression logic
- no SwiftUI dependency
- deterministic output
- stable handling of first-time exercises
- unit-safe weight values

## Future extensions

- exercise-specific strategies
- rep-goal progression
- percentage progression
- RIR/RPE-aware recommendations
- volume progression
- adaptive deloads
