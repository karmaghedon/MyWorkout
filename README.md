# 💪 MyWorkout

A production-quality **iPhone workout tracking application** built with **SwiftUI**, featuring intelligent progression, analytics, exercise education, and comprehensive workout management.

---

# Overview

MyWorkout is designed to be more than just a workout tracker.

Its long-term vision is to become a complete personal training platform that combines:

- 📈 Intelligent progression
- 📚 Exercise education
- 🏋️ Workout logging
- 📊 Performance analytics
- ❤️ Recovery insights

The project follows a clean, scalable architecture built around reusable SwiftUI components and testable business logic.

---

# Features

## Core Functionality

- ✅ workout templates
- ✅ active workout sessions
- ✅ resumable workout persistence
- ✅ set logging and workout history
- ✅ previous-performance lookup
- ✅ automatic warm-up generation
- ✅ double-progression recommendations
- ✅ rest timers
- ✅ plate loading calculations
- ✅ equipment inventory
- ✅ custom exercises
- ✅ exercise education content
- ✅ personal records
- ✅ training-volume analytics
- ✅ recovery and fatigue warnings
- ✅ CSV export
- ✅ JSON backup and restore
- ✅ pound and kilogram display support

---

## Technical Highlights

- Native SwiftUI
- Component-based UI
- Clean architecture
- Testable business logic
- File-based persistence
- Async file operations
- Cached analytics
- Centralized input validation
- Accessibility support
- Dark Mode support
- iPhone-only optimized

---

# Requirements

- iOS 17.0+
- Xcode 15+
- Swift 5.9+
- iPhone target

---

# Installation

## Clone Repository

```bash
git clone <repository-url>
cd MyWorkout
```

## Open Project

```bash
open MyWorkout.xcodeproj
```

## Run

1. Select an iPhone Simulator or physical iPhone.
2. Press **⌘R**
3. Build & Run

---

## Architecture at a glance

```text
SwiftUI Views
      |
Reusable Components
      |
Observable Stores
      |
Domain Models and Logic Engines
      |
Repositories and Persistence
```

The application root creates shared stores and injects them through SwiftUI environment objects.

```text
MyWorkoutApp
 ├── WorkoutLogStore
 ├── WorkoutTemplateStore
 ├── EquipmentInventoryStore
 ├── UserSettingsStore
 ├── ActiveWorkoutStore
 ├── CustomExerciseStore
 └── AnalyticsCache
```

---

## Documentation

Start with:

- `Docs/README.md`
- `Docs/Architecture/Architecture.md`
- `Docs/Architecture/Persistence.md`
- `Docs/Architecture/TestingStrategy.md`
- `Docs/Development/DevelopmentRoadmap.md`
- `Docs/Development/ReleaseChecklist.md`


---

# Development Principles

This project follows several core principles:

- Architecture before implementation
- Reusable components first
- Native SwiftUI whenever possible
- Thin Views
- Testable business logic
- Component-driven UI
- Small safe commits
- Production-quality code

---

## Project status

Phases 1–19 are complete, including the persistence integrity baseline,
logic test baseline, documentation consolidation, folder migration, and
responsibility-focused cleanup.

The current work is:

```text
Phase 20 — Stabilization and release readiness
```

Primary stabilization work includes release builds, regression testing,
fresh-install and upgrade-path validation, backup compatibility, accessibility,
and final release documentation.

---

# License

Private project.

---

# Author

Built with ❤️ for lifters who enjoy tracking progress.

---

# Acknowledgements

- Exercise information curated from reputable fitness resources.
- Inspired by modern strength training applications.
- Built following modern iOS architecture and SwiftUI best practices.
