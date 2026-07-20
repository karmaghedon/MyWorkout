# Frontend Decision Log — F1.1 Entries

**Version:** 1.1  
**Date:** 2026-07-19  
**Status:** Approved

## FDL-001 — Five durable destinations

**Decision**  
Use Home, Library, Workout, Progress, and Profile as the permanent top-level destinations.

**Reason**  
These represent scalable product areas rather than individual features. History belongs to Progress; templates belong to Workout; equipment and backup belong to Profile.

**Consequences**
- Introduce a native five-tab app shell.
- Remove the dashboard's role as a global application menu.
- Each tab receives an independent `NavigationStack`.

---

## FDL-002 — Workout occupies the center position

**Decision**  
Place Workout at the center of the tab bar and allow it to receive distinctive visual emphasis in a later phase.

**Reason**  
Starting or resuming training is MyWorkout's primary user action.

**Consequences**
- Native semantics are established before custom styling.
- Visual emphasis must not move workout business logic into the tab bar.

---

## FDL-003 — Active workout is stateful navigation

**Decision**  
The Workout destination reflects `ActiveWorkoutStore` state: Workout when idle, Resume when active, and concise rest status while resting.

**Reason**  
An in-progress session is more important than offering another start action and must never be silently replaced.

**Consequences**
- The tab shell observes active-workout state but does not mutate it.
- Resume routes to the existing session in the Workout stack.
- Existing replacement confirmation behavior remains mandatory.

---

## FDL-004 — Independent navigation stacks

**Decision**  
Each tab owns its own `NavigationStack` and path.

**Reason**  
Users expect tab state to remain intact when switching destinations. A global stack creates coupling and confusing Back behavior.

**Consequences**
- Navigation state survives tab switches.
- Routes cannot accidentally push into an unrelated destination.
- Feature route ownership can be introduced incrementally later.

---

## FDL-005 — Modal creation, pushed browsing and editing

**Decision**  
Use sheets for bounded creation flows and push navigation for browsing, details, and most editing.

**Reason**  
Creation is a temporary task returning to the current context; detail navigation represents location within the product hierarchy.

**Consequences**
- Create Template remains a sheet.
- Create Custom Exercise becomes a sheet.
- Exercise Detail, Workout Detail, Template Editor, and Custom Exercise editing remain pushes.

---

## FDL-006 — Workout session remains a push destination

**Decision**  
Keep `WorkoutSessionView` as a push destination during F1 rather than converting it to a full-screen cover.

**Reason**  
Native navigation is easier to reason about, test, restore, and make accessible. Immersive presentation can be reconsidered after UX testing.

**Consequences**
- Workout owns the session route.
- Leaving the screen does not cancel the session or timers.
- A custom full-screen experience is explicitly deferred.

---

## FDL-007 — Relocate custom exercises to Library

**Decision**  
Custom exercise management belongs to Library.

**Reason**  
Custom exercises are content in the exercise encyclopedia, not app configuration.

**Consequences**
- Remove Custom Exercises from the dashboard/manage grouping.
- Library becomes the entry point for built-in and user-created exercise content.

---

## FDL-008 — Present Export as Backup & Data

**Decision**  
Keep the source type temporarily but present `ExportView` as Backup & Data under Profile.

**Reason**  
The current feature includes import, export, and backup responsibilities; “Export” is too narrow.

**Consequences**
- User-facing title changes later in a focused UI step.
- A source-file rename is optional and should not be bundled into F1.2.

---

## FDL-009 — Defer feature-specific route enums

**Decision**  
Do not split `AppRoute` into several feature route enums in the same commit that introduces the app shell.

**Reason**  
That would combine two architectural concepts and increase migration risk.

**Consequences**
- F1.2 may temporarily reuse existing route mechanisms.
- Route ownership becomes a separate build-safe refactor after independent stacks are working.
