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

- ✅ Workout session management with live timer
- ✅ Exercise library with detailed exercise information
- ✅ Workout template creation and editing
- ✅ Intelligent progression engine
- ✅ Automatic warm-up recommendations
- ✅ Plate loading calculator
- ✅ Workout history
- ✅ Performance analytics
- ✅ Personal records
- ✅ Recovery analysis
- ✅ Equipment inventory management
- ✅ CSV export
- ✅ Metric (kg) and Imperial (lb) support
- ✅ Active workout persistence
- ✅ Rest timers with haptic feedback

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

# Project Structure

```
MyWorkout
│
├── Models/
│   ├── Exercise
│   ├── Workout
│   ├── WorkoutLog
│   └── ...
│
├── Stores/
│   ├── WorkoutLogStore
│   ├── ActiveWorkoutStore
│   ├── WorkoutTemplateStore
│   ├── EquipmentInventoryStore
│   └── UserSettingsStore
│
├── Logic/
│   ├── ProgressionEngine
│   ├── WarmupEngine
│   ├── PlateCalculator
│   ├── RecoveryAnalyzer
│   ├── ExercisePerformanceAnalyzer
│   └── ...
│
├── Views/
│   ├── Components/
│   └── Screens
│
├── Theme/
│
├── Utilities/
│
├── Data/
│
└── Docs/
```

---

# Architecture

MyWorkout follows a clean layered architecture.

```
Views
   ↓
Stores
   ↓
Models
   ↓
Logic
```

## Views

Pure presentation layer built from reusable SwiftUI components.

Responsibilities:

- UI composition
- User interaction
- Navigation

No business logic.

---

## Stores

ObservableObjects responsible for:

- State management
- Persistence
- Coordination between Views and Logic

Current stores:

- WorkoutLogStore
- ActiveWorkoutStore
- WorkoutTemplateStore
- EquipmentInventoryStore
- UserSettingsStore
- AnalyticsCache

---

## Models

Codable data structures representing the application domain.

Examples:

- Exercise
- Workout
- WorkoutLog
- ProgressionRule
- ExerciseSessionState

---

## Logic

Pure functions with no UI dependencies.

Current engines include:

- ProgressionEngine
- WarmupEngine
- PlateCalculator
- RecoveryAnalyzer
- ExercisePerformanceAnalyzer

These components are deterministic and designed for unit testing.

---

# Current Features

## Workout Tracking

- Live workout timer
- Active workout resume
- Set logging
- Rest timers
- Previous performance
- Warm-up recommendations

---

## Exercise Library

Each exercise includes:

- Name
- Equipment
- Difficulty
- Primary muscles
- Secondary muscles
- Instructions
- Tips
- Common mistakes
- Safety warnings
- Progression strategy

---

## Progression

Supports:

- Double Progression
- Slow Progression
- Reps then Weight
- Bodyweight Progression

Automatic:

- Weight increases
- Deloads
- Stall detection

---

## Equipment Inventory

Configure:

- Barbell weight
- Plate inventory
- Dumbbells

Used for:

- Plate calculations
- Workout starting weights

---

## Analytics

Current analytics include:

- Volume tracking
- Personal records
- Recovery analysis
- Performance trends
- Muscle group volume

---

# Weight System

Internally, **all weights are stored in pounds**.

The UI automatically converts between:

- Pounds (lb)
- Kilograms (kg)

This ensures progression, calculations, and historical data remain consistent regardless of the selected display unit.

---

# Data Storage

Application data is stored using file-based persistence.

Examples:

```
Application Support/
├── workout_logs.json
├── workout_templates.json
├── equipment_inventory.json
└── settings (UserDefaults)
```

---

# Testing

The architecture is designed for unit testing.

Primary test targets:

- ProgressionEngine
- WarmupEngine
- PlateCalculator
- RecoveryAnalyzer
- Weight conversion
- Store persistence

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

# Planned Features

- Exercise images
- Exercise videos
- Muscle diagrams
- Favorites
- Search improvements
- Apple Health integration
- CloudKit sync
- Advanced progression recommendations
- Recovery dashboard
- Training readiness
- Custom exercise creation
- Backup & Restore

---

# Performance Goals

Designed to comfortably scale to:

- 500+ exercises
- 20,000+ workouts
- Multiple years of user history

Optimizations include:

- Cached analytics
- Cached exercise registry
- Debounced recalculations
- Async persistence
- Incremental updates

---

# Contributing

This is currently a personal project.

Suggestions and constructive feedback are always welcome.

---

# Code Style

- Swift API Design Guidelines
- Native SwiftUI
- Views under ~200 lines
- Reusable components
- Pure business logic
- Centralized styling through `AppTheme`

---

# Documentation

Additional documentation:

- `Docs/Architecture.md`
- `Docs/DevelopmentRoadmap.md`

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
