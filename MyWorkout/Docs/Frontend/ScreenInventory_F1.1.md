# MyWorkout Screen Inventory

**Version:** 1.2  
**Date:** 2026-08-19  
**Status:** F7 audited

## Status Legend

- **Root** — permanent destination root.
- **Push** — pushed inside the owning tab's `NavigationStack`.
- **Sheet** — modal task flow.
- **Embedded** — reusable section/component, not independently routed.
- **Review later** — valid today, but a future information-architecture decision remains.

## Home

| Screen | Current role | Target role | Presentation | Notes |
|---|---|---|---|---|
| `DashboardView` | Home root | Home root | Root | Done (F3) — today-focused greeting, hero action, stats, recent activity; the duplicate global menu cards are gone (F3 removed Start Workout/History/Settings, F4-F7 removed the remaining Manage/Progress links once their destinations had a proper tab home). Rename to `HomeView` still pending, cosmetic only. |
| `DashboardStatsView` | Home summary card | Home summary | Embedded | Done — today-focused overview (Workouts/Latest/Alerts). |
| `DashboardStoreErrorsView` | Store error list | Home/global error presentation | Embedded | Kept Home-owned; centralizing globally remains a future option, not required. |

## Library

| Screen | Current role | Target role | Presentation | Notes |
|---|---|---|---|---|
| `ExerciseLibraryView` | Library root | Library root | Root | Reachable as the Library tab since F1's tab shell. |
| `ExerciseDetailView` | Exercise detail | Library detail | Push | Done. |
| `CustomExercisesView` | Custom exercise management | Custom exercise management | Push | Done (F5) — reachable via a toolbar link from `ExerciseLibraryView`, not just Home. |
| `CustomExerciseFormView` — create | Pushed via `AppRoute.createCustomExercise` | Creation task | Push (recommended: Sheet) | Still a push, not the sheet this doc recommends — see FDL-016. Functionally complete either way. |
| `CustomExerciseFormView` — edit | Pushed via `AppRoute.editCustomExercise` | Editing detail | Push | Done — matches target. |

## Workout

| Screen | Current role | Target role | Presentation | Notes |
|---|---|---|---|---|
| `StartWorkoutView` | Workout tab root | Workout root/hub | Root | Already supports idle/resume/rest states (from F1's tab shell work). Rename to `WorkoutView`/`WorkoutHubView` still pending, cosmetic only. |
| `WorkoutSessionView` | Nested destination from Start Workout | Active session | Push | Owned exclusively by Workout stack. Done. |
| `TemplatesView` | Template management | Template management | Push | Done (F4) — reachable via a "Manage Templates" toolbar link from `StartWorkoutView`, not just Home. |
| `CreateWorkoutTemplateView` | Sheet from Templates | Template creation | Sheet | Keep. |
| `TemplateEditorView` | Push from Templates/global route | Template editing | Push | Keep. |
| `TemplateExercisePickerView` | Template editor child | Exercise selection | Embedded/child flow | Keep within template feature. |

## Progress

| Screen | Current role | Target role | Presentation | Notes |
|---|---|---|---|---|
| `ProgressHubView` | Progress tab root | Progress root | Root | Done (F6). Named `ProgressHubView`, not this doc's original `ProgressView` suggestion — that name collides with SwiftUI's own `ProgressView` type. |
| `HistoryView` | Progress hub destination | Workout history | Push | Was the Progress tab's direct root before F6; now one level deeper, pushed from `ProgressHubView`. |
| `WorkoutLogDetailView` | History detail | Workout detail | Push | Keep. |
| `AnalyticsView` | Progress hub destination | Analytics overview | Push | Done (F6) — reachable from `ProgressHubView`, not just Home. |
| `StrengthTrendView` | Progress hub destination | Strength trends | Push | Done (F6). Review later for possible Analytics integration. |

## Profile

| Screen | Current role | Target role | Presentation | Notes |
|---|---|---|---|---|
| `ProfileHubView` | Profile tab root | Profile root | Root | Done (F7). |
| `SettingsView` | Profile hub destination | Preferences | Push | Was the Profile tab's direct root before F7; now one level deeper, pushed from `ProfileHubView`. |
| `EquipmentInventoryView` | Profile hub destination | Equipment configuration | Push | Done (F7) — reachable from `ProfileHubView`, not just Home. |
| `ExportView` | Profile hub destination | Backup & Data | Push | Done (F7); user-facing label already reads "Backup & Data" (FDL-008). |

## Shared Modal and Dialog Inventory

| Flow | Current presentation | Decision |
|---|---|---|
| Create template | Sheet with nested `NavigationStack` | Keep. |
| Create custom exercise | Global push route | Change to sheet. |
| Edit custom exercise | Global push route | Keep as push under Library. |
| Active workout conflict | Confirmation dialog | Keep. |
| Cancel active workout | Confirmation dialog | Keep. |
| Leave active workout with logged sets | Session dialog | Keep behavior; ensure navigation remains Workout-owned. |
| Archive/delete custom exercise | Confirmation dialogs | Keep. |
| Blocked custom exercise deletion | Alert | Keep. |
| Import/export outcomes | Alerts | Keep. |

## Reusable View Inventory

The following are components, not navigable screens:

- Analytics sections and cards.
- Exercise education sections.
- Equipment inventory sections and rows.
- Workout session cards, timer, set controls, notes, warmups, previous performance, and dialogs.
- Shared controls: `AppEmptyStateView`, `InfoBadge`, `SecondaryButton`, `ValidatedNameField`, `StoreErrorBanner`, and `FlowLayout`.

## Navigation Risks — status as of F7

1. ~~`ExerciseLibraryView` has no visible route from the current dashboard root.~~ Resolved (F1) — it's the Library tab root.
2. ~~One global `NavigationStack` owns unrelated product areas.~~ Resolved (F1) — five independent per-tab stacks.
3. ~~Dashboard cards duplicate the role that permanent tabs will provide.~~ Resolved (F3 removed Start Workout/History/Settings; F4-F7 removed the remaining Templates/Equipment/Custom Exercises/Backup/Analytics/Strength links once each had a real tab-owned home).
4. `AppRoute` still centralizes unrelated feature routes from every product area. Not yet split into feature-owned routes (§7 of `NavigationArchitecture_F1.1.md`) — still an open, deliberately deferred item, not a regression.
5. `StartWorkoutView` still owns an internal Boolean navigation destination (`showWorkoutSession`) alongside `AppRoute` value-based navigation (its new "Manage Templates" toolbar link). Two patterns coexisting in one screen remains a real, if minor, inconsistency.
6. Some destinations still use value-based routing (`NavigationLink(value:)` against `AppRoute`) while others use direct `NavigationLink { Destination() }` construction (e.g. `ExerciseLibraryView`'s exercise rows). Not yet unified.
7. ~~Home, Progress, and Profile do not yet exist as clear product roots.~~ Resolved (F3 gave Home real today-focused content; F6/F7 gave Progress and Profile real hub roots instead of defaulting into History/Settings).

Items 4-6 remain open; none block any current user flow.

## F1.1 Result

All current screens now have an assigned destination and presentation style. F4-F7 (see `FrontendRoadmap_F1.0.md`) have since implemented that assignment for every screen this document flagged as reachable only from Home.
