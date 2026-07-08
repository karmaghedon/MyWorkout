If a future developer reads only one document before modifying MyWorkout, it should be this one.

# MyWorkout Architecture

Version: 1.1

Status: Living Document

Note: This file replaces the former `MyWorkoutArchitecture.md`, which duplicated this document and had
drifted out of sync with it. There is now a single source of truth for architecture decisions.

---

# Vision

MyWorkout is designed to become more than a workout tracker.

It should evolve into:

- Workout Logger
- Progression Engine
- Exercise Encyclopedia
- Personal Trainer
- Analytics Platform

Every architectural decision should support one or more of these goals.

---

# Design Philosophy

The application should prioritize:

- Maintainability
- Reusability
- Scalability
- Consistency
- Native SwiftUI
- Production-quality architecture

Getting a feature working is never the final objective.

The objective is building a feature that will still be easy to maintain years from now.

---

# Architecture Principles

## 1. Architecture before implementation

Never build a feature before considering its long-term architecture.

Ask:

- Can it be reused?
- Does it scale?
- Does it fit the product vision?

---

## 2. Reusable before duplicated

Whenever the same UI appears twice, extract a reusable component.

Prefer

ExerciseHeaderView

instead of duplicated SwiftUI.

---

## 3. Views assemble components

Views should primarily compose reusable components and be responsible for layout only.

Business logic belongs in:

- Stores
- Models
- Services

Views should stay small.

Target: 150–200 lines maximum. Views that grow past this should be split into
subcomponents (see `Views/Components/`).

Example

ExerciseDetailView

↓

ExerciseHeaderView

↓

ExerciseMusclesView

↓

ExerciseInstructionsView

↓

ExerciseTipsView

↓

ExerciseWarningsView

---

## 4. Native SwiftUI first

Whenever possible, prefer native SwiftUI APIs.

Examples

- NavigationStack
- Layout protocol
- Observation
- SwiftData (future)

Avoid custom implementations when native solutions exist.

---

## 5. Small safe iterations

Each implementation step should:

- compile
- be independently testable
- be commit ready

Never leave the project in a broken state.

---

## 6. Production quality

Assume the application will eventually contain:

- 500+ exercises
- 20,000+ workouts
- years of user data

Design accordingly.

---

## 7. Failures are surfaced, never swallowed

Every store that persists data (`WorkoutLogStore`, `WorkoutTemplateStore`,
`EquipmentInventoryStore`, `UserSettingsStore`, `ActiveWorkoutStore`) exposes
`lastSaveError` / `lastLoadError` so the UI can inform the user instead of silently
losing data. `print()`-only error handling is not acceptable for anything that
touches user data — a store must always give the UI a way to know something failed.

---

## 8. Pure logic is unit tested

Anything in `Logic/` (`ProgressionEngine`, `RecoveryAnalyzer`, `WarmupEngine`,
`PlateCalculator`, `WeightConversion`, etc.) is pure and side-effect-free by design,
specifically so it can be unit tested. New logic in this layer should ship with tests
in `MyWorkoutTests/` covering at least its primary branches and edge cases (empty
input, first-time use, stalled progression, etc.).

---

# Product Architecture

MyWorkout

├── Dashboard
│
├── Exercise Library
│
├── Workout Templates
│
├── Active Workout
│
├── Workout History
│
├── Progression Engine
│
├── Analytics
│
├── Exercise Knowledge Base
│
└── Settings

---

# Exercise Architecture

Exercise

├── Identity
│   ├── Name
│   ├── Category
│   ├── Equipment
│   ├── Difficulty
│   └── Aliases
│
├── Muscles
│   ├── Primary
│   └── Secondary
│
├── How To
│   ├── Instructions
│   ├── Coaching Tips
│   ├── Common Mistakes
│   ├── Safety
│   └── Beginner Notes
│
├── Progression
│   ├── Strategy
│   ├── Rep Range
│   ├── Increase Rules
│   ├── Deload Rules
│   └── Stall Rules
│
├── Media
│   ├── Image
│   ├── Video
│   └── Muscle Diagram
│
├── Analytics
│   ├── Personal Records
│   ├── Recent History
│   ├── Estimated 1RM
│   ├── Volume
│   └── Last Performed
│
└── Future
    ├── Alternatives
    ├── Variations
    ├── Related Exercises
    └── FAQ

---

# Application Layers

Application

↓

Feature Views

↓

Reusable Components

↓

Stores

↓

Models

↓

Persistence

---

# Project Structure

MyWorkout

├── Models
│
├── Stores
│
├── Logic
│
├── Data
│
├── Views
│
├── Components
│   ├── Common
│   ├── Exercise
│   ├── Inventory
│   └── WorkoutSession
│
├── Helper
│
├── Theme
│
├── Utilities
│
└── Docs

---

# UI Architecture

Reusable UI should be preferred over screen-specific implementations.

Consistency matters more than creativity — every screen should feel like the same application.

Current reusable components

Common

- DetailRow
- InfoBadge
- FlowLayout

Exercise

- ExerciseRowView
- ExerciseHeaderView
- ExerciseMusclesView
- ExerciseInstructionsView
- ExerciseTipsView
- ExerciseWarningsView

Future

- ExerciseProgressView
- ExerciseHistoryView
- ExerciseImageView
- ExerciseVideoView
- WorkoutCard
- ProgressCard
- SectionCard
- EmptyStateView
- StatTile

New components should be extracted before duplication occurs.

---

# Data Philosophy

Data models should describe the product.

Never design models around today's UI.

Prefer

Equipment

instead of

String

Prefer

ExerciseTip

instead of

String

when future expansion is expected.

Leave extension points without introducing unnecessary complexity.

---

# Development Workflow

For every feature

1. Design architecture.
2. Identify reusable components.
3. Build reusable components.
4. Implement one polished example.
5. Validate (including unit tests for any new pure logic).
6. Roll out everywhere.

Never duplicate work.

---

# Commit Strategy

Preferred commits

feat:

refactor:

fix:

Every commit should

- compile
- solve one concern
- remain independently testable

---

# Long-Term Product Vision

Phase 1 — Workout Logger

✓ Templates

✓ Workout Session

✓ Progression

✓ History

✓ Rest Timer

---

Phase 2 — Exercise Encyclopedia

☑ Exercise Row

☑ InfoBadge

☑ FlowLayout

☑ Exercise Detail

☐ Exercise Header

☐ Exercise Images

☐ Exercise Videos

☐ Muscle Diagram

☐ Personal Records

☐ Exercise History

☐ Search

☐ Favorites

---

Phase 3 — Analytics

Personal Records

Volume Tracking

Progress Charts

Workout Insights

Training Consistency

---

Phase 4 — Personal Trainer

Workout Suggestions

Adaptive Progression

Fatigue Management

Recovery Tracking

Training Readiness

---

Phase 5 — Platform Expansion

Apple Health

Cloud Sync

Watch App

Export / Import

Sharing

---

# Definition of Done

A feature is complete when

✓ Architecture supports future growth

✓ UI is reusable

✓ Code is maintainable

✓ Builds successfully

✓ No unnecessary duplication

✓ Fits the product vision

✓ Any new persistence path surfaces failures via `lastSaveError` / `lastLoadError`

✓ Any new pure logic has unit test coverage in `MyWorkoutTests/`

Working code is only the first milestone.

Maintainable architecture is the final goal.
