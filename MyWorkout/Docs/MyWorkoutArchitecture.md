# MyWorkout Architecture

Version: 1.0
Status: Living Document

---

# Vision

MyWorkout is not just a workout logger.

It is designed to become:

- Workout Logger
- Progression Engine
- Exercise Encyclopedia
- Personal Trainer
- Analytics Platform

Every architectural decision should support at least one of these goals.

---

# Core Principles

## Architecture First

Design the architecture before implementing features.

Questions to ask:

- Can this be reused?
- Does it scale?
- Does it fit the overall architecture?

---

## Reusable Before Duplicated

If the same UI appears twice,
extract a reusable component.

Never duplicate layouts.

---

## Small Safe Iterations

Every step should:

- Compile
- Be testable
- Be commit-ready

Never leave the project in a broken state.

---

## Views Assemble Components

Views should be responsible for layout only.

Business logic belongs in:

- Stores
- Models
- Services

Views should stay small.

Target:

150–200 lines maximum.

---

## Native SwiftUI First

Always prefer Apple's native APIs.

Examples:

- Layout protocol
- NavigationStack
- Observation
- SwiftData (future)

Avoid custom implementations when native solutions exist.

---

## Production Quality

Assume:

- 500+ exercises
- 20,000+ workouts
- Years of maintenance

Avoid shortcuts that increase future technical debt.

---

# Product Architecture

App

├── Dashboard
├── Exercise Library
├── Workout Templates
├── Active Workout
├── Workout History
├── Progression Engine
├── Analytics
├── Exercise Knowledge Base
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
│   ├── Loading Rules
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
│   ├── History
│   ├── Volume
│   ├── Estimated 1RM
│   └── Last Performed
│
└── Future
    ├── Alternatives
    ├── Variations
    ├── FAQ
    └── Related Exercises

---

# Project Folder Structure

MyWorkout

├── Models
├── Stores
├── Services
├── Data
├── Views
│
├── Components
│   ├── Common
│   ├── Exercise
│   ├── Workout
│   └── Dashboard
│
├── Exercise
├── Workout
├── History
├── Dashboard
├── Templates
└── Settings

---

# UI Philosophy

Every screen should feel like the same application.

Consistency matters more than creativity.

Reusable components include:

- ExerciseHeaderView
- ExerciseRowView
- InfoBadge
- DetailRow
- FlowLayout
- SectionCard
- StatTile
- EmptyStateView

New components should be extracted before duplication occurs.

---

# Data Philosophy

Design models around the product,
not around today's UI.

Prefer

Equipment

instead of

String

Prefer

ExerciseTip

instead of

String

when future expansion is expected.

Avoid premature complexity,
but always leave room for growth.

---

# Development Workflow

For every feature:

1. Define architecture.
2. Build reusable components.
3. Implement one polished example.
4. Validate.
5. Roll out everywhere.

Never implement the same feature multiple times.

---

# Commit Strategy

Prefer:

feat:
refactor:
fix:

Every commit should:

- Build successfully
- Be independently testable
- Solve one architectural concern

---

# Long-Term Roadmap

Phase 1
✅ Workout Logger

Phase 2
Exercise Encyclopedia

Phase 3
Exercise Education

Phase 4
Analytics

Phase 5
Personal Trainer

Phase 6
Cloud Sync

Phase 7
Apple Health

Phase 8
Watch App

---

# Definition of Done

A feature is complete when:

✓ Architecture supports future growth
✓ Code is reusable
✓ UI is consistent
✓ Builds successfully
✓ No duplication
✓ Ready for production

Getting it to work is not enough.

It should also be maintainable.
