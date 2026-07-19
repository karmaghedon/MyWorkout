# Folder Structure

MyWorkout uses a layered, feature-oriented folder structure. The organization separates application composition, shared infrastructure, reusable domain behavior, user-facing features, resources, and documentation.

## Application source layout

```text
MyWorkout/
├── App/
│   └── Navigation/
├── Core/
│   ├── Errors/
│   ├── Persistence/
│   ├── Protocols/
│   ├── Theme/
│   ├── Utilities/
│   └── Validation/
├── Domain/
│   ├── Analytics/
│   ├── Backup/
│   ├── Equipment/
│   ├── Exercise/
│   ├── Settings/
│   └── Workout/
├── Features/
│   ├── Analytics/
│   ├── CustomExercises/
│   ├── Dashboard/
│   ├── Equipment/
│   ├── ExerciseLibrary/
│   ├── Export/
│   ├── History/
│   ├── Settings/
│   ├── Shared/
│   ├── Templates/
│   └── WorkoutSession/
├── Resources/
└── Docs/
```

The `MyWorkoutTests` target remains at the repository level and mirrors the domain behavior it protects.

## App

`App` contains application composition and top-level navigation.

```text
App/
├── MyWorkoutApp.swift
└── Navigation/
    └── AppRoute.swift
```

Responsibilities:

- construct application-level stores
- inject environment dependencies
- define top-level navigation types
- start the root SwiftUI hierarchy

Feature and business logic must not move into this folder.

## Core

`Core` contains infrastructure that is shared across multiple domains and features.

### Errors

Shared error contracts and error-reporting behavior.

### Persistence

Cross-domain persistence infrastructure, including versioned envelopes and active-workout persistence contracts.

### Protocols

Narrow capability protocols used to decouple infrastructure such as backup import from concrete stores.

### Theme

Application-wide visual tokens.

### Utilities

Small reusable helpers and extensions with no feature ownership.

### Validation

Validation reused by forms, stores, and import workflows.

A type belongs in `Core` only when it is genuinely cross-cutting. Feature-specific convenience code should remain with its feature.

## Domain

`Domain` contains product models, deterministic behavior, repositories, and shared state owners.

### Analytics

```text
Analytics/
├── Logic/
├── Models/
└── Stores/
```

Contains analytics snapshots, calculations, analyzers, and the analytics cache.

### Backup

Contains the backup payload, document representation, and import coordinator.

### Equipment

```text
Equipment/
├── Loading/
├── Models/
└── Stores/
```

Contains inventory models, unit conversion, plate loading, and equipment persistence orchestration.

### Exercise

```text
Exercise/
├── Logic/
├── Models/
├── Registry/
├── Repositories/
├── Seed/
├── Sources/
└── Stores/
```

Contains built-in and custom exercise identity, lookup, validation support, persistence, and registry assembly.

### Settings

Contains settings models and the shared settings store.

### Workout

```text
Workout/
├── Export/
├── Models/
├── Progression/
├── Repositories/
├── Session/
├── Stores/
└── Warmup/
```

Contains workout history, templates, active sessions, progression, warm-ups, rest rules, and CSV export behavior.

## Features

`Features` contains user-facing SwiftUI workflows. A feature folder owns its screens and feature-specific components.

Examples:

```text
Features/WorkoutSession/
├── WorkoutSessionView.swift
├── StartWorkoutView.swift
└── Components/
```

```text
Features/CustomExercises/
├── CustomExercisesView.swift
├── CustomExerciseFormView.swift
└── Components/
```

### Shared

`Features/Shared` contains reusable UI components used by more than one feature, such as common empty states, validation fields, and layout components.

Only reusable presentation belongs here. Domain logic must not be placed in `Features/Shared`.

## Resources

Contains non-code application resources:

- asset catalogs
- preview assets
- launch storyboard
- entitlements

## Docs

Contains architecture, feature, workflow, roadmap, and release documentation.

## Placement rules

Use these questions when deciding where a type belongs:

1. Does it compose the application? Place it in `App`.
2. Is it cross-cutting infrastructure? Place it in `Core`.
3. Is it a reusable product model or rule? Place it in `Domain`.
4. Is it a user-facing workflow or SwiftUI component? Place it in `Features`.
5. Is it a non-code asset? Place it in `Resources`.

## Dependency direction

Preferred direction:

```text
App
 ↓
Features
 ↓
Domain
 ↓
Core
```

`Core` must not depend on feature code.

`Domain` must not depend on SwiftUI views.

Feature code may use domain and core types but should not duplicate their behavior.

## Folder-change rule

Folder movement is performed in small, buildable batches. After each structural change:

- verify Xcode file references
- verify target membership
- build the application
- run the complete test suite
- update documentation paths
