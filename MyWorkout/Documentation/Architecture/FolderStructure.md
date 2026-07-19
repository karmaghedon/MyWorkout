# Folder Structure

This document describes the current project structure and the rules for future cleanup.

## Current source layout

```text
MyWorkout/
├── Data/
├── Domain/
├── Helper/
├── Logic/
├── Models/
├── Navigation/
├── Persistence/
├── Protocols/
├── Repositories/
├── Stores/
├── Theme/
├── Utilities/
├── Views/
│   └── Components/
└── Docs/
```

## Folder responsibilities

### Data

Static or assembled data sources.

Examples:

- seed exercises
- default templates
- exercise registry
- exercise source adapters
- equipment inventory model currently stored here

### Domain

Domain-facing interfaces and assembly that do not belong to UI or persistence.

Examples:

- exercise provider contracts
- exercise registry factory
- workout-start result

### Helper

Small application helpers with focused behavior.

Examples:

- haptics
- weight formatting

During Phase 19, this folder should be reviewed for consolidation with `Utilities`.

### Logic

Deterministic business logic and validation.

Subdomains include:

- progression
- warm-ups
- plate loading
- analytics
- recovery
- workout-session behavior
- weight conversion
- validation

### Models

Codable domain values and UI-independent result structures.

Subfolders should be used when a domain has multiple related types.

### Navigation

Route and navigation-related types.

### Persistence

Cross-domain persistence infrastructure.

Examples:

- active workout persistence
- versioned persistence envelope

### Protocols

Narrow capability protocols shared by infrastructure or tests.

Examples:

- backup replacement contracts

Repository protocols may remain near their repository implementations unless Phase 19 establishes one consistent rule.

### Repositories

Persistence boundaries for collection-based domains.

Each repository pair generally includes:

```text
DomainRepository.swift
FileDomainRepository.swift
```

### Stores

Main-actor observable state owners.

Stores coordinate mutations, validation, persistence, and error exposure.

### Theme

Application-wide visual tokens.

### Utilities

Cross-cutting utilities and extensions.

### Views

Top-level feature screens.

### Views/Components

Reusable UI grouped by feature or interaction type.

Current groups include:

- Analytics
- Common
- Exercise
- Export
- Feedback
- Forms
- Inventory
- WorkoutSession

### Docs

Architecture, feature, development, and release documentation.

## Test layout

```text
MyWorkoutTests/
├── Engine tests
├── Analyzer tests
├── Store tests
├── Validator tests
├── Repository mocks
├── Test factories
└── Shared test utilities
```

Phase 19 should group these by domain if movement improves discoverability without creating unnecessary nesting.

## Folder rules

1. A folder must communicate responsibility.
2. Do not create a folder for one file unless the category is expected to grow.
3. Keep feature-specific UI components with their feature group.
4. Keep deterministic logic out of views.
5. Keep persistence implementation out of models.
6. Avoid catch-all folders such as `Misc`.
7. Prefer one naming convention: singular type names, plural category folders.
8. Move files only as a behavior-neutral cleanup step.

## Phase 19 target direction

A likely future structure is:

```text
MyWorkout/
├── App/
├── Core/
│   ├── Persistence/
│   ├── Protocols/
│   ├── Validation/
│   └── Utilities/
├── Domain/
│   ├── Exercise/
│   ├── Workout/
│   ├── Equipment/
│   └── Analytics/
├── Features/
│   ├── Dashboard/
│   ├── ExerciseLibrary/
│   ├── WorkoutSession/
│   ├── Templates/
│   ├── History/
│   ├── Analytics/
│   ├── Settings/
│   └── Backup/
└── Resources/
```

This is a direction, not an automatic mandate. Phase 19 must validate whether each move improves navigation and dependency clarity.
