# MyWorkout Architecture Development Workflow

> **Purpose**
>
> This document defines how architectural work is planned, implemented, reviewed, committed, and recorded in the MyWorkout project.
>
> It complements `MyWorkout Architecture Evolution Roadmap.md`.
>
> The roadmap explains **where the project is going**.
>
> This workflow explains **how each architectural step must be executed**.

---

# 1. Core Rule

Every architectural change must be completed as a small, safe, reviewable step.

The required sequence is:

```text
Architecture Review
        ↓
Scope Definition
        ↓
Implementation
        ↓
Build Validation
        ↓
Behavior Validation
        ↓
Commit
        ↓
Roadmap Update
        ↓
Architecture Review
```

Do not skip directly from an idea to implementation.

---

# 2. One Architectural Concept Per Step

Each step should introduce only one meaningful architectural concept.

Good examples:

```text
Step 1 → Centralize weight conversion
Step 2 → Rename session state fields
Step 3 → Extract active workout persistence
Step 4 → Introduce active workout snapshot
```

Avoid combining unrelated changes such as:

```text
Weight conversion
+ navigation
+ analytics
+ persistence
+ UI redesign
```

Each step must remain small enough to understand, validate, and revert safely.

---

# 3. Required Deliverables After Every Architectural Commit

Every architecture-related commit must produce three deliverables.

## 3.1 Code Change

The implementation must:

- compile successfully
- preserve existing behavior unless behavior change is intentional
- avoid duplicating existing components
- follow current project architecture
- remain limited to the active roadmap task

## 3.2 Updated Architecture Roadmap

After each commit, update:

```text
MyWorkout Architecture Evolution Roadmap.md
```

The update must include:

- active phase
- current task
- newly completed task
- next recommended task
- progress table
- architectural decision log, when applicable
- known risks or deferred work

## 3.3 Architecture Review

Every completed step should end with a short review.

Example:

```text
Architecture Review

✔ The implementation follows the roadmap.
✔ No duplicate component was introduced.
✔ Existing behavior remains intact.
✔ The project builds successfully.
✔ The next architectural task is clearly defined.
```

If concerns remain, record them explicitly:

```text
Architecture Review

⚠ The change is safe to merge.
⚠ ActiveWorkoutStore remains large.
⚠ Timer extraction is still deferred to Phase 5.
```

---

# 4. Current Phase Resume Point

The roadmap must contain a section near the top called:

```text
Current Phase
```

Required format:

```markdown
# Current Phase

**Active Phase:** Phase 1 – Weight System

**Current Task:** 1.2 – Audit Entire Project

**Last Completed Commit:**
- Centralized WeightConversion
- Removed direct conversion formulas from session UI

**Next Step:**
Audit progression and warm-up calculations for unit safety.

**Do Not Work On Yet:**
- Active workout persistence extraction
- Navigation architecture
- Repository layer
```

This section is the official resume point for the next development session.

---

# 5. Workflow Before Writing Code

Before implementation, answer these questions.

## Architecture

1. Which roadmap phase does this change belong to?
2. Is this the smallest safe architectural step?
3. Does an existing abstraction already solve part of the problem?
4. Can this be reused elsewhere?
5. Does the change preserve current architecture boundaries?

## Product

1. Which MyWorkout goal does this support?
   - Workout Logger
   - Progression Engine
   - Exercise Encyclopedia
   - Personal Trainer
   - Analytics Platform
2. Does the model reflect the product concept rather than the current UI?
3. Will this still make sense with hundreds of exercises and years of workout history?

## Risk

1. Could this corrupt persisted data?
2. Could this break active workouts?
3. Could this change logged workout history?
4. Could this affect kg/lb conversion?
5. Is migration required?
6. Is a rollback path clear?

Do not start implementation until the scope is understood.

---

# 6. Implementation Rules

## 6.1 Keep Views Thin

Views should assemble components and send user actions to stores or engines.

Preferred:

```text
WorkoutSessionView
        ↓
ExerciseSessionCardView
        ↓
CurrentSetCardView
```

Avoid placing business logic directly in SwiftUI views.

## 6.2 Reuse Before Duplication

If the same UI or behavior appears twice, stop and extract it.

Examples:

```text
InfoBadge
NumericInputField
StoreErrorBanner
ExerciseHeaderView
EmptyStateView
```

## 6.3 Business Logic Belongs in Engines

Examples:

```text
ProgressionEngine
WarmupEngine
WorkoutSessionEngine
PlateCalculator
RecoveryAnalyzer
```

Engines should be:

- deterministic
- UI-independent
- easy to test
- based on domain models

## 6.4 Stores Coordinate State

Stores may:

- expose observable state
- coordinate engines
- trigger persistence
- handle user actions

Stores should not:

- contain large UI formatting logic
- duplicate domain calculations
- know unnecessary file-system details after persistence is extracted

## 6.5 Persisted Data Requires Extra Care

Before changing a Codable model, determine:

- whether existing user data can still decode
- whether default values are needed
- whether a schema version is required
- whether migration logic is required

Never silently break persisted data.

---

# 7. Build and Validation Gate

Every step must pass a validation gate before commit.

## Required Checks

- Project builds successfully
- No new compiler warnings
- Existing feature still works
- New behavior works
- Active workout can resume
- Workout can still be finished
- Logged sets contain expected values
- Unit switching does not corrupt stored weight
- Persistence errors are not silently ignored

## Feature-Specific Checks

Add checks appropriate to the change.

Example for weight work:

```text
lb display → edit → log → stored pounds correct
kg display → edit → log → stored pounds correct
switch lb/kg → same physical load preserved
progression increment remains correct
warm-up weights remain correct
```

---

# 8. Commit Rules

Use small, descriptive commits.

Preferred prefixes:

```text
feat:
refactor:
fix:
test:
docs:
```

Examples:

```text
refactor: centralize weight conversion
fix: preserve edited session values when logging sets
refactor: extract active workout persistence
docs: update architecture roadmap progress
```

Each commit must:

- compile
- represent one logical change
- avoid unrelated formatting changes
- be understandable from the commit message alone

---

# 9. Roadmap Update Procedure

After each architectural commit, update the roadmap in this order.

## 9.1 Mark Completed Work

Example:

```markdown
### 1.1 Centralize WeightConversion

Status: Completed
```

## 9.2 Update Current Task

Example:

```markdown
**Current Task:** 1.2 – Audit Entire Project
```

## 9.3 Define the Next Step

The next step must be explicit.

Good:

```text
Audit CurrentSetCardView, ProgressionEngine, and WarmupEngine for direct unit conversion.
```

Too vague:

```text
Continue weight work.
```

## 9.4 Update Progress Table

Use:

```text
🟢 Completed
🟡 In Progress
⚪ Planned
🔴 Blocked
```

## 9.5 Add Architecture Decision Record

Add an entry when a long-term decision is made.

---

# 10. Architecture Decision Log

Use this format:

```markdown
## YYYY-MM-DD — Decision Title

### Decision

Describe the chosen architectural direction.

### Context

Explain the problem and alternatives considered.

### Reason

Explain why this option was selected.

### Impact

Describe affected models, stores, engines, views, persistence, or tests.

### Status

Accepted
```

Example:

```markdown
## 2026-07-10 — Canonical Weight Storage

### Decision

All workout and progression weights are stored internally in pounds.

### Context

The user may display and enter values in pounds or kilograms.

### Reason

A canonical internal unit prevents history, analytics, progression, and unit switching from changing the physical load.

### Impact

All UI conversion must pass through WeightConversion.

### Status

Accepted
```

---

# 11. Deferred Work

When a valid improvement is discovered but does not belong to the current task:

1. Do not implement it immediately.
2. Record it under the correct future roadmap phase.
3. Add a brief reason for deferral.
4. Continue the active task.

Example:

```text
Deferred:
ActiveWorkoutStore should be split.

Reason:
Current phase is weight-system stabilization.
Persistence extraction belongs to Phase 3.
```

This prevents architectural drift.

---

# 12. When to Stop a Refactor

Stop and reassess when:

- more than one architecture concept is being introduced
- the diff becomes difficult to review
- unrelated files begin changing
- the project stops compiling
- persisted data compatibility becomes unclear
- the implementation requires speculative abstractions
- the current task no longer matches the roadmap

Split the work into smaller steps before continuing.

---

# 13. Definition of Done

An architectural step is complete only when all items below are true.

```text
[ ] The scope matches one roadmap task.
[ ] The implementation compiles.
[ ] Existing behavior was validated.
[ ] New behavior was validated.
[ ] No duplicate architecture was introduced.
[ ] Persisted-data impact was considered.
[ ] The commit is small and descriptive.
[ ] The roadmap was updated.
[ ] The architecture decision log was updated when needed.
[ ] The next step is explicit.
```

---

# 14. Standard Output After Each Commit

After every architecture-related commit, provide:

## Commit Message

```text
refactor: centralize weight conversion
```

## Completed Work

```text
- Replaced direct conversion formulas
- Routed display values through WeightConversion
- Preserved canonical stored pounds
```

## Validation

```text
- Build passed
- lb session entry validated
- kg session entry validated
- Existing logs remained readable
```

## Updated Roadmap

Return the complete updated roadmap file.

## Architecture Review

```text
✔ Direction remains aligned with the roadmap.
✔ No premature complexity introduced.
✔ Ready for the next task.
```

---

# 15. Relationship Between Project Documents

```text
README.md
    Product overview and setup

Architecture.md
    Stable target architecture

MyWorkout Architecture Evolution Roadmap.md
    Ordered sequence of architectural improvements

MyWorkout Architecture Development Workflow.md
    Process used to execute every architectural improvement
```

Each document has a separate responsibility and should not duplicate the others unnecessarily.

---

# Final Rule

The goal is not to finish changes quickly.

The goal is to build MyWorkout so that it remains understandable, maintainable, and safe as it grows into:

- a workout logger
- a progression engine
- an exercise encyclopedia
- a personal trainer
- an analytics platform
