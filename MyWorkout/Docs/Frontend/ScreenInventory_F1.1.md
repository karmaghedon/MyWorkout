# MyWorkout Screen Inventory

**Version:** 1.1  
**Date:** 2026-07-19  
**Status:** F1.1 audited

## Status Legend

- **Root** — permanent destination root.
- **Push** — pushed inside the owning tab's `NavigationStack`.
- **Sheet** — modal task flow.
- **Embedded** — reusable section/component, not independently routed.
- **Review later** — valid today, but a future information-architecture decision remains.

## Home

| Screen | Current role | Target role | Presentation | Notes |
|---|---|---|---|---|
| `DashboardView` | Entire app root and menu | Home root | Root | Later rename to `HomeView`; remove duplicate global menu cards. |
| `DashboardStatsView` | Dashboard overview card | Home summary | Embedded | Evolve toward today-focused content. |
| `DashboardStoreErrorsView` | Store error list | Home/global error presentation | Embedded | Keep during F1; centralize later. |

## Library

| Screen | Current role | Target role | Presentation | Notes |
|---|---|---|---|---|
| `ExerciseLibraryView` | Not reachable from current dashboard | Library root | Root | Important current navigation gap. |
| `ExerciseDetailView` | Exercise detail | Library detail | Push | Keep. |
| `CustomExercisesView` | Dashboard manage destination | Custom exercise management | Push | Move under Library. |
| `CustomExerciseFormView` — create | Pushed through global route | Creation task | Sheet | Recommended modal creation flow. |
| `CustomExerciseFormView` — edit | Pushed through global route | Editing detail | Push | Retains context and Back behavior. |

## Workout

| Screen | Current role | Target role | Presentation | Notes |
|---|---|---|---|---|
| `StartWorkoutView` | Dashboard destination | Workout root/hub | Root | Later rename. Must support idle/resume/rest states. |
| `WorkoutSessionView` | Nested destination from Start Workout | Active session | Push | Owned exclusively by Workout stack. |
| `TemplatesView` | Dashboard destination | Template management | Push | Move under Workout. |
| `CreateWorkoutTemplateView` | Sheet from Templates | Template creation | Sheet | Keep. |
| `TemplateEditorView` | Push from Templates/global route | Template editing | Push | Keep. |
| `TemplateExercisePickerView` | Template editor child | Exercise selection | Embedded/child flow | Keep within template feature. |

## Progress

| Screen | Current role | Target role | Presentation | Notes |
|---|---|---|---|---|
| `ProgressView` | Missing | Progress root | Root | New lightweight screen required in F1.2 or the following safe step. |
| `HistoryView` | Dashboard destination | Workout history | Push | Already consolidated from duplicate history/calendar concepts. |
| `WorkoutLogDetailView` | History detail | Workout detail | Push | Keep. |
| `AnalyticsView` | Dashboard destination | Analytics overview | Push | Keep. |
| `StrengthTrendView` | Dashboard destination | Strength trends | Push | Review later for possible Analytics integration. |

## Profile

| Screen | Current role | Target role | Presentation | Notes |
|---|---|---|---|---|
| `ProfileView` | Missing | Profile root | Root | New screen required. |
| `SettingsView` | Dashboard destination | Preferences | Push | Move under Profile. |
| `EquipmentInventoryView` | Dashboard destination | Equipment configuration | Push | Move under Profile. |
| `ExportView` | Dashboard destination | Backup & Data | Push | User-facing rename recommended. |

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

## Current Navigation Risks

1. `ExerciseLibraryView` has no visible route from the current dashboard root.
2. One global `NavigationStack` owns unrelated product areas.
3. Dashboard cards duplicate the role that permanent tabs will provide.
4. `AppRoute` centralizes unrelated feature routes and will become increasingly difficult to maintain.
5. `StartWorkoutView` owns an internal Boolean navigation destination while the dashboard also owns global route navigation, creating two navigation patterns.
6. Some destinations use value-based routing while others use direct `NavigationLink` destinations.
7. Home, Progress, and Profile do not yet exist as clear product roots.

## F1.1 Result

All current screens now have an assigned destination and presentation style. No source code should change until F1.2 begins.
