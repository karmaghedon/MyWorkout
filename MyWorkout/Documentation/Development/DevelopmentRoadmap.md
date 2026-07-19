# MyWorkout Development Roadmap

## Completed foundation

Phases 1–14 established the core product and architecture:

- exercise library
- workout templates
- active workout sessions
- workout history
- progression
- warm-ups
- plate loading
- equipment inventory
- units
- analytics
- recovery
- reusable UI
- validation
- persistence infrastructure

## Phase 15 — Custom Exercises

- ✅ 15.7A Store tests
- ✅ 15.7B Import validation
- ✅ 15.7C Validator tests
- ✅ 15.7D Store replacement tests
- ✅ 15.8 Name validation consolidation
- ✅ 15.9 Integration audit

## Phase 16 — Persistence Integrity

- ✅ Save atomicity
- ✅ Backup atomicity
- ✅ Equipment persistence verification where required

## Phase 17 — Logic and Persistence Test Baseline

### Deterministic logic

- ✅ ProgressionEngine
- ✅ WarmupEngine
- ✅ PlateCalculator
- ✅ WeightConversion
- ✅ RecoveryAnalyzer and specialized analyzers
- ✅ Analytics
- ✅ Backup compatibility foundations

### Persistence regressions

- ✅ WorkoutLogStore
- ✅ WorkoutTemplateStore
- ✅ ActiveWorkoutStore
- ✅ EquipmentInventoryStore
- ✅ UserSettingsStore
- ✅ CustomExerciseStore
- ✅ Backup importer testability protocols

## Current phase

# Phase 18 — Documentation

- ✅ 18.1 Documentation structure
- ✅ 18.2 Architecture documentation
- ✅ 18.3 Persistence and backup documentation
- ✅ 18.4 Feature documentation
- ✅ 18.5 Development standards and workflow
- ✅ 18.6 Release checklist
- ☐ 18.7 Add project screenshots when final UI stabilizes
- ☐ 18.8 Final documentation-to-code consistency review after Phase 19

## Phase 19 — Architecture Cleanup

### 19.1 Folder structure audit

- evaluate `Core`, `Domain`, and feature-oriented grouping
- move files in small buildable batches
- keep behavior unchanged

### 19.2 Dependency audit

- identify unnecessary concrete dependencies
- keep protocols narrow
- remove unused abstractions
- verify dependency direction

### 19.3 View-size audit

- identify views exceeding approximately 150–200 lines
- extract reusable components only where it adds value
- avoid extraction for its own sake

### 19.4 Dead-code cleanup

- remove unused types
- remove commented-out code
- remove duplicate files
- remove obsolete migration code only when compatibility policy allows it

### 19.5 Naming and folder consistency

- standardize folder names
- standardize test-support naming
- review `Helper` versus `Utilities`
- review model placement

### 19.6 Documentation refresh

- update folder diagrams after final movement
- update architecture paths
- update README

## Phase 20 — Stabilization

- release configuration build
- full unit test pass
- manual regression checklist
- fresh install
- upgrade from an existing install
- backup export
- backup import
- older backup compatibility
- active workout interruption and restore
- corrupted persistence behavior
- performance review
- accessibility review
- version and build numbering
- release notes
- version 1.0 architecture review

## Deferred product ideas

- exercise search
- favorites
- exercise images and video
- muscle diagrams
- richer progression strategies
- readiness input
- cloud sync
- wearable integration
- expanded analytics
