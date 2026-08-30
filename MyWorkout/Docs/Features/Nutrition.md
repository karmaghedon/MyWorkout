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

## Main types (Phase 3 — Daily Nutrition Log)

This app tracks calories and macros, not a food diary — Phase 3 was
originally scoped as a per-food-item log (name, meal, macros per item)
but was redirected before shipping: **there is no food name or meal
type anywhere in this feature.** Instead there is one editable record
per calendar day.

- `DailyNutritionLog` — a day's total macros (`date, proteinG, carbsG,
  fatG`). `calories` is a *computed* property (`proteinG×4 + carbsG×4
  + fatG×9`, the standard kcal-per-gram rule) rather than a stored
  field, so it can never drift out of sync with the macros it's
  derived from — the UI never accepts a typed calorie count.
- `DailyNutritionLogRepository` (protocol) / `FileDailyNutritionLogRepository`
  — file-backed JSON persistence (`daily_nutrition_logs.json`), same
  `PersistedEnvelope` pattern as every other domain in this app.
- `DailyNutritionLogStore` — `@MainActor ObservableObject`, mirrors
  `MacroGoalStore`/`BodyMeasurementLogStore`'s persistence-error
  surfacing and background save queue. Its mutation is `upsert(date:
  proteinG:carbsG:fatG:)` rather than `add` — at most one record
  exists per day, replaced in place as that day's totals change, never
  accumulated from separate entries. `entry(on:)` looks up one day's
  record (or `nil` if that day has none yet).
- `NutritionHealthKitServicing` (protocol) / `NutritionHealthKitService`
  (concrete) — `logDailyTotals(proteinG:carbsG:fatG:calories:date:)`
  upserts that day's four dietary `HKQuantitySample`s (energy, protein,
  carbs, fat). Since each save represents the *whole* day's total
  rather than one more item, saving again for the same day first
  deletes this app's previously-written samples for that day (found
  via a fixed `"com.myworkout.dailyNutritionTotal"` metadata marker
  combined with a same-day date predicate) before writing the fresh
  ones — otherwise editing a day's macros would leave stale samples
  behind and double-count in any HealthKit aggregate. The metadata
  marker, not a per-save random id, is what makes this idempotent: it
  only ever touches samples this app itself wrote as a daily total,
  never a per-item entry from another app or Apple Health directly.

## Local persistence (Phase 3)

`DailyNutritionLog` follows the app's standard Tier-2 pattern:
`~/Library/Application Support/MyWorkout/daily_nutrition_logs.json`,
wrapped in `PersistedEnvelope`, schema version 1. Included in
`AppBackup` (version 5) via a `DailyNutritionLogReplacing` conformance,
appended to `BackupImportHandler`'s replacement order.

## UI (Phase 3)

`LogNutritionView` — a read-only computed-calories summary at the top,
then `BigStepperControl` (same shared stepper `GoalsView` uses) for
protein/carbs/fat, and a save button that upserts today's record. No
list of entries, no food name field, no meal picker — loading the
screen pre-fills today's already-saved macros if there are any, so
it's an edit form for "today," not an ever-growing log. Reached from
Home (`DashboardView`) via a "Log Nutrition" quick action next to "Log
Weight," and the `AppRoute.logNutrition` route.

## Testing (Phase 3)

`DailyNutritionLogStoreTests` covers load/upsert (insert vs. same-day
replace vs. separate-day)/delete/replaceAll/`entry(on:)`, plus a direct
check that `calories` follows the 4/4/9 rule, all against
`MockDailyNutritionLogRepository` — never the real file-backed
repository. `MockNutritionHealthKitService` exists for
`LogNutritionView`'s own use in a future UI test but has no dedicated
test yet (harmless, same as Phase 1's `MockBodyMetricsHealthKitService`
at the time it was added). Same hard rule as every other domain in
this app: no test may construct `FileDailyNutritionLogRepository()`'s
default initializer or a real `HKHealthStore`-backed service.

## Future extensions

- Editing an existing goal in place rather than only add/delete.
- Phase 4 (Home unification): `TodayNutritionCard` reading
  `activeGoal(on: .now)` alongside `DailyNutritionLogStore.entry(on: .now)`.
- Phase 7/8: FatSecret pulls a day's calorie/macro totals directly
  (not an item-by-item diary) into the same `DailyNutritionLog` model
  — the sync coordinator's dedup key becomes "has this day already
  been synced," not a per-item id, matching this phase's shift away
  from a food diary.
