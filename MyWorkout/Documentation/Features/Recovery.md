# Recovery

## Purpose

Recovery analysis highlights training patterns that may benefit from additional rest or programming adjustment.

It provides guidance, not medical diagnosis.

## Main analyzers

- `RecoveryAnalyzer`
- `VolumeSpikeAnalyzer`
- `PerformanceDeclineAnalyzer`
- `IntraWorkoutFatigueAnalyzer`

## Volume spike

Compares recent workload against prior workload using an injectable calendar and current date.

Future-dated logs are ignored.

## Performance decline

Detects meaningful decline across recent performances according to deterministic thresholds.

## Intra-workout fatigue

Evaluates set-to-set performance decline inside a completed exercise.

## Aggregation

`RecoveryAnalyzer` combines specialized analyzer outputs into recovery warnings used by analytics.

## Design

Each analyzer has one responsibility.

This split improves:

- testability
- threshold clarity
- future extension
- avoidance of a single oversized analyzer

## Limitations

Recovery output depends on logged training data and does not currently include:

- sleep
- soreness
- heart-rate data
- nutrition
- illness
- subjective readiness

## Future extensions

- user-reported readiness
- muscle-specific recovery windows
- configurable sensitivity
- trend confidence
- wearable integration
