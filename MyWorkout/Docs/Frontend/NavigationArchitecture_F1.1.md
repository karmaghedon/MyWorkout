# MyWorkout Navigation Architecture

**Version:** 1.1  
**Date:** 2026-07-19  
**Status:** Approved baseline for F1 implementation

**Implementation status (2026-08-19):** Sections 2-4's target screen
ownership is now implemented for every destination — see
`ScreenInventory_F1.1.md` and `FrontendRoadmap_F1.0.md` (F1, F3-F7 done)
for current status. Two items from this document remain open and are
tracked, not forgotten: §7's feature-owned route split (`AppRoute` is
still one shared enum), and custom exercise creation is still a push
destination rather than the sheet §4's Library section recommends (see
FDL-016). Everything else below — tab ownership, push/sheet/cover/alert
rules, the active-workout contract — reflects the shipped app, not just
the plan.

## 1. Purpose

This document defines the top-level navigation model for MyWorkout before the native app shell is implemented. It is the source of truth for tab ownership, push navigation, modal presentation, active-workout behavior, and route placement.

## 2. Primary Destinations

MyWorkout uses five durable product destinations:

1. **Home** — today-focused overview, active-workout status, coaching signals, and quick actions.
2. **Library** — built-in and custom exercises, education, search, filters, and exercise detail.
3. **Workout** — start or resume training, manage workout templates, and run the active session.
4. **Progress** — workout history, analytics, strength trends, personal records, and recovery insights.
5. **Profile** — settings, equipment, units, backup, export, import, and future personal profile options.

Recommended visual order:

```text
Home    Library    Workout    Progress    Profile
```

The center Workout destination is the primary action and may receive distinctive visual emphasis after the native navigation architecture is proven.

## 3. Root Ownership

Each primary destination owns an independent `NavigationStack` and navigation path.

```text
AppShellView
├── HomeNavigationStack
├── LibraryNavigationStack
├── WorkoutNavigationStack
├── ProgressNavigationStack
└── ProfileNavigationStack
```

Switching tabs must preserve each stack's navigation state. A tab must not push screens into another tab's stack.

## 4. Screen-to-Destination Map

### Home

**Root**
- `DashboardView` — rename conceptually to `HomeView` during a later focused refactor.

**Home responsibilities**
- Current-day overview.
- Active workout status and resume action.
- Recent progress summary.
- Store/persistence error visibility.
- Contextual shortcuts only; not a duplicate menu of every app feature.

**Relocation required**
- Remove the current dashboard sections that act as a full application menu after tabs are introduced.
- `DashboardStatsView` remains Home-owned but should eventually become a richer, today-focused summary.
- `DashboardStoreErrorsView` remains Home-owned until a shared global error presentation strategy is introduced.

### Library

**Root**
- `ExerciseLibraryView`

**Push destinations**
- `ExerciseDetailView`
- `CustomExercisesView`
- `CustomExerciseFormView` in edit mode

**Sheet destinations**
- `CustomExerciseFormView` in create mode is recommended as a sheet because it is a contained creation task that returns to the Library context.

**Notes**
- Custom exercises belong to Library, not Profile or Settings. They are exercise content, not configuration.
- Built-in and custom exercises should eventually share search and filtering behavior.

### Workout

**Root**
- `StartWorkoutView` — rename conceptually to `WorkoutView` or `WorkoutHubView` when the tab shell is introduced.

**Push destinations**
- `WorkoutSessionView`
- `TemplatesView`
- `TemplateEditorView`

**Sheet destinations**
- `CreateWorkoutTemplateView`

**Conditional root behavior**
- No active session: show workout templates and start actions.
- Active session: prominent Resume state.
- Rest timer running: display concise timer status without replacing the destination title or causing layout instability.

**Critical rule**
- Entering Workout while a session is active must route toward the existing active workout and must never silently replace it.

### Progress

**Root**
- A new lightweight `ProgressView` is recommended to organize the three existing progress areas.

**Push destinations**
- `HistoryView`
- `WorkoutLogDetailView`
- `AnalyticsView`
- `StrengthTrendView`
- Exercise-related detail links reached from analytics

**Potential future merge**
- `AnalyticsView` and `StrengthTrendView` should remain separate initially.
- Later, Strength Trends may become a section or subdestination within Analytics if the information architecture proves too fragmented.

**Notes**
- History is a feature of Progress, not a permanent top-level destination.
- Recent workout links from Analytics remain within the Progress stack.

### Profile

**Root**
- A new `ProfileView` or `ProfileRootView` is required.

**Push destinations**
- `SettingsView`
- `EquipmentInventoryView`
- `ExportView` (recommended display title: Backup & Data)

**Future destinations**
- Personal information.
- Goals.
- Appearance.
- App information and support.

**Rename recommendation**
- Present `ExportView` to users as **Backup & Data** because the screen includes export, import, and backup responsibilities.

## 5. Presentation Rules

### Push
Use push navigation when the user is browsing deeper into the current destination or expects Back navigation.

Examples:
- Exercise Library → Exercise Detail
- History → Workout Log Detail
- Templates → Template Editor
- Progress → Analytics
- Profile → Equipment

### Sheet
Use a sheet for bounded creation or editing tasks that return to the same context and do not represent a new permanent place in the app.

Examples:
- Create Workout Template
- Create Custom Exercise

Sheets must embed their own `NavigationStack` when they contain navigation titles, toolbar actions, validation, or nested selection flows.

### Full-Screen Cover
Reserve full-screen covers for immersive flows that should visually leave the normal application shell.

Current recommendation:
- Do not use a full-screen cover for `WorkoutSessionView` in F1. The active workout should remain a push destination owned by the Workout stack so system navigation behavior stays predictable.
- Reconsider only after workout-session UX testing demonstrates a clear benefit.

### Alert
Use alerts for informational acknowledgement or non-destructive failure states.

Examples:
- Import/export failure.
- Permanent deletion blocked because an exercise is referenced.
- Missing or unavailable route data.

### Confirmation Dialog
Use confirmation dialogs for destructive choices or alternatives between multiple meaningful actions.

Examples:
- Cancel active workout.
- Replace active workout.
- Archive or permanently delete a custom exercise.

## 6. Active Workout Navigation Contract

1. `ActiveWorkoutStore` remains the single source of truth for session existence and session state.
2. The tab bar and app shell only render state; they do not create, replace, or cancel workouts.
3. Selecting Workout while an active workout exists should expose Resume immediately.
4. Selecting Resume routes to `WorkoutSessionView` in the Workout stack.
5. Starting another template while a workout is active must keep the existing confirmation flow.
6. Switching tabs must not stop elapsed time or rest timing.
7. Popping `WorkoutSessionView` must leave the active session running.
8. Completing or cancelling the session returns the Workout destination to its normal state.
9. A restored session after app launch must produce the same Resume state as a newly started session.
10. No route outside Workout may directly replace the active workout.

## 7. Route Ownership

The current global `AppRoute` mixes routes from every product area. F1.2 may preserve it temporarily to reduce risk, but the target architecture is feature-owned routes:

```swift
enum LibraryRoute: Hashable { ... }
enum WorkoutRoute: Hashable { ... }
enum ProgressRoute: Hashable { ... }
enum ProfileRoute: Hashable { ... }
```

Do not introduce all feature route enums in the same step as the native shell. First establish the tab shell and independent stacks; then split route ownership in a dedicated safe refactor.

## 8. Screens to Merge, Rename, or Relocate

| Current screen | Decision | Reason |
|---|---|---|
| `DashboardView` | Keep initially; later rename to `HomeView` | It becomes a destination rather than the root menu. |
| `StartWorkoutView` | Keep initially; later rename to `WorkoutView` or `WorkoutHubView` | It will represent the Workout tab in both idle and active states. |
| `HistoryView` | Relocate under Progress | History is evidence of progress, not a top-level product area. |
| `TemplatesView` | Relocate under Workout | Templates prepare workouts. |
| `CustomExercisesView` | Relocate under Library | Custom exercises are library content. |
| `EquipmentInventoryView` | Relocate under Profile | Equipment is user configuration. |
| `ExportView` | Relocate under Profile; display as Backup & Data | It includes backup, import, and export. |
| `StrengthTrendView` | Keep under Progress; evaluate later merge into Analytics | Avoid premature consolidation. |
| Dashboard menu cards | Remove after tab shell adoption | They duplicate permanent navigation. |

## 9. F1.2 Implementation Boundary

The next implementation step should introduce only:

- `AppTab`
- `AppShellView`
- Five native `TabView` destinations
- One `NavigationStack` per tab
- Existing environment object injection unchanged
- Home selected at launch

Do not introduce the custom tab appearance, feature-specific route enums, visual redesign, or Home content redesign in the same commit.

## 10. Acceptance Criteria

- Every existing screen has a documented owner.
- The five primary destinations are stable.
- Push, sheet, cover, alert, and confirmation-dialog rules are defined.
- Active workout behavior is explicit and cannot be overwritten accidentally.
- F1.1 changes documentation only.
