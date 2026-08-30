# Nutrition

## Purpose

Weight/calorie/macro tracking's nutrition half — calorie and macro
targets today, food logging and HealthKit-backed diary sync in later
phases of the same feature. This doc grows with each phase rather than
splitting into one file per model.

## Main types (Phase 2 — Macro Goals)

- `MacroGoal` — a calorie/macro target that took effect on a given
  date (`effectiveDate, calories, proteinG, carbsG, fatG`). Local-only:
  HealthKit has no concept of a goal, only logged samples.
- `MacroGoalRepository` (protocol) / `FileMacroGoalRepository` —
  file-backed JSON persistence, same `PersistedEnvelope` pattern as
  every other domain in this app (`macro_goals.json`).
- `MacroGoalStore` — `@MainActor ObservableObject`, mirrors
  `BodyMeasurementLogStore` exactly (persistence-error surfacing,
  background save queue, `isPersistenceWritable` guard).

## Goal resolution

`MacroGoalStore.activeGoal(on date:)` resolves which goal applies to a
given day: the goal with the latest `effectiveDate` that is still
`<= date`. If no goal has started yet as of `date` (every goal is
future-dated), it falls back to the goal with the latest
`effectiveDate` overall, so a future-dated goal never leaves "today"
with nothing to show. This is a pure function over `goals` — no
HealthKit or I/O involved — and is the piece Phase 4's Home nutrition
card will call into.

## Local persistence

`MacroGoal` follows the app's standard Tier-2 pattern:
`~/Library/Application Support/MyWorkout/macro_goals.json`, wrapped in
`PersistedEnvelope`, schema version 1. Included in `AppBackup` (bumped
to version 4) via a `MacroGoalReplacing` conformance, appended to
`BackupImportHandler`'s replacement order.

## UI

`GoalsView` — a single screen combining a "New Goal" entry form
(effective date picker + `BigStepperControl` for calories/protein/
carbs/fat, reusing the same shared stepper the workout session screens
use — no new numeric-entry component needed since goals are natural
whole numbers, unlike weigh-in fields) and a "History" list of
previously set goals, newest first, with swipe-to-delete. Reached from
Profile (`ProfileHubView`) via a new "Health & Nutrition" section's
"Macro Goals" row and the `AppRoute.macroGoals` route.

## Testing

`MacroGoalStoreTests` covers load/add/delete/replaceAll against
`MockMacroGoalRepository` — never the real file-backed repository —
plus explicit boundary coverage for `activeGoal(on:)`: exact-date
match, a gap between goals, and querying before any goal has started.
Same hard rule as every other domain in this app: no test may
construct `FileMacroGoalRepository()`'s default initializer.

## Future extensions

- Editing an existing goal in place rather than only add/delete.
- Phase 3 (Manual Food Log): `FoodLogEntry`, HealthKit dietary writes.
- Phase 4 (Home unification): `TodayNutritionCard` reading
  `activeGoal(on: .now)` alongside today's logged totals.
- Phase 7/8: FatSecret-connected diary sync.
