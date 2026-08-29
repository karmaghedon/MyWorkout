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
