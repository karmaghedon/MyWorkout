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

# Phase 20 — Stabilization

Phase 19 is complete. The codebase now uses the final App/Core/Domain/Features/Resources/Docs structure, and the last cleanup audit found no additional high-value view extraction that justified added complexity.

## Phase 18 — Documentation

- ✅ 18.1 Documentation structure
- ✅ 18.2 Architecture documentation
- ✅ 18.3 Persistence and backup documentation
- ✅ 18.4 Feature documentation
- ✅ 18.5 Development standards and workflow
- ✅ 18.6 Release checklist
- ☐ 18.7 Add project screenshots when final UI stabilizes
- ✅ 18.8 Documentation-to-code consistency review after Phase 19

## Phase 19 — Architecture Cleanup

- ✅ 19.1 App/Core/Domain/Features/Resources/Docs structure established
- ✅ 19.2 Dependency audit
- ✅ 19.3 View-size and responsibility audit
- ✅ 19.4 Dead and commented code cleanup
- ✅ 19.5 Duplicate test-file cleanup
- ✅ 19.6 Naming and folder consistency review
- ✅ 19.7 Documentation refresh

Completed responsibility extractions:

- active workout persistence coordinator
- equipment inventory converter
- custom exercise row
- dashboard store error presentation
- template exercise picker
- custom exercise mutation consolidation

The remaining large files were reviewed by responsibility rather than line count. No further extraction is planned unless a future feature creates a clear reusable boundary.

## Phase 20 — Stabilization checklist

- ☐ release configuration build
- ☐ full unit test pass
- ☐ manual regression checklist
- ☐ fresh install
- ☐ upgrade from an existing install
- ☐ backup export
- ☐ backup import
- ☐ older backup compatibility
- ☐ active workout interruption and restore
- ☐ corrupted persistence behavior
- ☐ performance review
- ☐ accessibility review
- ☐ version and build numbering
- ☐ release notes
- ☐ version 1.0 architecture review

## Phase 21 — Weight, Macro & Training Tracking

Multi-week feature adding HealthKit-backed weight/nutrition tracking
and FatSecret food-diary sync, built in 8 independently-verified
phases. Full breakdown, cross-cutting rules, and per-phase backup
version: `Docs/Development/WeightMacroTrainingRoadmap.md`.

- ✅ 21.1 HealthKit Foundation + Log Weight — `AppBackup` v3
- ✅ 21.2 Macro Goals — `AppBackup` v4
- ✅ 21.3 Manual Food Log Entry — `AppBackup` v5
- ✅ 21.4 Home/Today Nutrition Unification
- ✅ 21.5 Weekly Report
- ☐ 21.6 Progress Chart
- ☐ 21.7 FatSecret OAuth Connection — `AppBackup` v6
- ☐ 21.8 FatSecret Food Diary Sync

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
