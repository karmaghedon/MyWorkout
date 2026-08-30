# Weight, Macro & Training Tracking Roadmap

## Purpose

Tracks the phased rollout of the weight/calorie/macro tracking feature
(referenced as Phase 21 in `DevelopmentRoadmap.md`). HealthKit is the
backbone for weight/body-fat%/waist/nutrition, so it syncs across
devices via iCloud and shows up in Apple Health/Watch with no extra
work; FatSecret provides food-diary data via OAuth; a few fields
HealthKit doesn't cover (neck circumference, macro goals, FatSecret
connection state) get local storage following this app's existing
hand-rolled JSON persistence pattern — there is no SwiftData/Core Data
anywhere in this app, and this feature deliberately doesn't introduce
one.

Each phase is independently buildable and ends in a real on-device
check before the next phase starts. **No sixth tab** — every new
screen attaches to an existing tab (Home, Progress, or Profile) rather
than expanding the 5-tab chrome.

## Phase status

- ✅ **Phase 1 — HealthKit Foundation + Log Weight.** HealthKit
  authorization, `LogWeightView` (weight required; body fat %, waist,
  neck optional). Weight/body fat %/waist write to HealthKit; neck has
  no HealthKit type, so it's the one field in local
  `BodyMeasurementLogStore`. `AppBackup` → v3. See
  `Docs/Features/WeightTracking.md`.
- ✅ **Phase 2 — Macro Goals.** Local-only `MacroGoal` history
  (`effectiveDate, calories, proteinG, carbsG, fatG`) via
  `MacroGoalStore`; `activeGoal(on:)` resolves which goal applies to a
  given day. `GoalsView` reached from Profile → Health & Nutrition →
  Macro Goals. `AppBackup` → v4. See `Docs/Features/Nutrition.md`.
- ☐ **Phase 3 — Manual Food Log Entry.** `FoodLogEntry` written to both
  HealthKit (`dietaryEnergyConsumed`/`dietaryProtein`/
  `dietaryCarbohydrates`/`dietaryFatTotal`) and local
  `FoodLogEntryStore`. `FoodLogView`, reached via a "Log Food" quick
  action on Home. `AppBackup` → v5.
- ☐ **Phase 4 — Home/Today Nutrition Unification.** `TodayNutritionCard`
  on `DashboardView` showing today's logged totals against the active
  macro goal. Pure UI composition — no new persistence.
- ☐ **Phase 5 — Weekly Report.** Computed (never stored) per-week
  weight/waist/neck cards, windowed by actual logging cadence rather
  than fixed calendar weeks. `WeeklyReportView`, reached from Progress.
- ☐ **Phase 6 — Progress Chart.** Swift Charts line chart of weight
  over time with optional waist/neck overlays and a 1M/3M/6M/1Y/All
  range picker. `BodyProgressView`, reached from Progress.
- ☐ **Phase 7 — FatSecret OAuth Connection.** 3-legged OAuth 1.0a via
  `ASWebAuthenticationSession`; tokens in Keychain only (never
  backed up). Requires migrating the app target from
  `GENERATE_INFOPLIST_FILE = YES` to a physical `Info.plist` to
  express the callback URL scheme. `FatSecretConnectionView`, reached
  from Profile. `AppBackup` → v6 (connection metadata only).
- ☐ **Phase 8 — FatSecret Food Diary Sync.** "Sync from FatSecret"
  pulls a day's diary, dedups by `fatSecretEntryId`, writes new
  entries to HealthKit + `FoodLogEntryStore`. Wires up the previously
  inert sync button in `FoodLogView`.

## Cross-cutting rules (every phase)

1. **Persistence**: every new durable model follows the existing
   Tier-2 pattern — a `<Name>Repository` protocol, a
   `File<Name>Repository` writing `PersistedEnvelope<[Value]>` JSON
   atomically, and a `@MainActor <Name>Store: ObservableObject` with
   `persistenceError` surfacing and an `isPersistenceWritable` guard.
2. **Testing — hard rule**: no test may construct a real
   `File<Name>Repository()` default initializer or a real
   `HKHealthStore`-backed service. `xcodebuild test` in this dev
   environment runs against the connected physical iPhone (CoreSimulator
   is broken here, so there is no sandboxed simulator) — a test that
   touches real persistence or real HealthKit can corrupt real
   production data or pop real permission dialogs. This already
   happened once to this project's real template data before the rule
   was written down. Every persistence/HealthKit dependency sits
   behind a narrow protocol with a hand-written mock.
3. **project.pbxproj registration**: this project has no synchronized
   folders — every new file needs a manually-added `PBXBuildFile` +
   `PBXFileReference` + group placement + build-phase entry.
4. **Verification**: compile-only simulator build → device build,
   install, and launch → the phase's on-device checklist → user
   confirms → only then commit and move to the next phase.
5. **Backup integration**: each phase that adds a durable local model
   bumps `AppBackup.currentVersion`, decodes the new field via
   `decodeIfPresent(...) ?? []`/`?? nil` so older backups stay
   readable, adds a `<Name>Replacing` protocol, and updates
   `Docs/Architecture/BackupSystem.md`. HealthKit-resident data
   (weight, waist, nutrition) is deliberately excluded from the JSON
   backup — it already lives in HealthKit/iCloud.
6. **Docs**: each phase gets/extends a `Docs/Features/<Name>.md`, with
   its filename added to `Docs/README.md`'s feature index.

## Backup version by phase

| Phase | `AppBackup.currentVersion` | New backed-up field |
|---|---|---|
| 1 | 3 | `bodyMeasurementLogs` |
| 2 | 4 | `macroGoals` |
| 3 | 5 | `foodLogEntries` |
| 7 | 6 | `fatSecretConnectionMetadata` |

Phases 4, 5, 6, and 8 add no new backed-up field.
