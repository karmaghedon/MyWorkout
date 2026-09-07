# Getting Started

## Prerequisites

- macOS with Xcode 15 or later
- iOS 17 SDK
- an iPhone simulator or physical iPhone
- Git

## Open and run

```bash
open MyWorkout.xcodeproj
```

Select the `MyWorkout` scheme and run on an iPhone destination.

## Run tests

Use:

```text
Product > Test
```

or:

```text
Command-U
```

The test target is `MyWorkoutTests`.

## First-launch behavior

On first launch, the app initializes:

- default workout templates
- default equipment inventory
- default user settings
- empty workout history
- empty custom exercise storage
- no active workout

The stores persist their state using either repositories, files, or UserDefaults according to their subsystem.

## Important development precautions

Before changing persistence code:

1. identify the existing schema and migration behavior
2. preserve old data until the new representation is safely written
3. avoid overwriting unreadable data
4. add regression tests
5. verify backup compatibility

Before changing workout-session state:

1. test starting a workout
2. test navigating away and resuming
3. test timer continuity
4. test set persistence
5. test cancel and finish behavior

## Documentation location

Project documentation is stored under:

```text
MyWorkout/Docs
```

The repository-level `README.md` provides the project overview.
