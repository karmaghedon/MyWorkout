import XCTest
@testable import MyWorkout

final class WorkoutSessionEngineTests: XCTestCase {

    // MARK: - Fixtures

    private func exercise(
        name: String = "Bench Press",
        equipment: ExerciseEquipment = .barbell,
        exerciseType: ExerciseType = .compound,
        strategy: ProgressionStrategy = .doubleProgression,
        targetWeightPounds: Double? = nil
    ) -> Exercise {
        Exercise(
            name: name,
            muscleGroup: .chest,
            equipment: equipment,
            instructions: "Push it",
            progressionRule: ProgressionRule(
                minReps: 8,
                maxReps: 12,
                increaseAmount: 5,
                deloadAmount: 10,
                stallLimit: 3
            ),
            exerciseType: exerciseType,
            progressionStrategy: strategy,
            targetWeightPounds: targetWeightPounds
        )
    }

    private func inventory(barbellWeight: Double = 45) -> EquipmentInventory {
        EquipmentInventory(
            unitSystem: .pounds,
            barbellWeight: barbellWeight,
            plates: [],
            dumbbells: []
        )
    }

    // MARK: - defaultStartingWeight

    func test_defaultStartingWeight_bodyweight_isAlwaysZero() {
        let ex = exercise(equipment: .barbell, exerciseType: .bodyweight)
        let weight = WorkoutSessionEngine.defaultStartingWeight(for: ex, equipmentInventory: inventory(barbellWeight: 45))
        XCTAssertEqual(weight, 0)
    }

    func test_defaultStartingWeight_barbellCompound_usesInventoryBarbellWeight() {
        let ex = exercise(equipment: .barbell, exerciseType: .compound)
        let weight = WorkoutSessionEngine.defaultStartingWeight(for: ex, equipmentInventory: inventory(barbellWeight: 45))
        XCTAssertEqual(weight, 45)
    }

    func test_defaultStartingWeight_nonBarbellCompound_isZero() {
        let ex = exercise(equipment: .cableOrBand, exerciseType: .compound)
        let weight = WorkoutSessionEngine.defaultStartingWeight(for: ex, equipmentInventory: inventory(barbellWeight: 45))
        XCTAssertEqual(weight, 0)
    }

    func test_defaultStartingWeight_isolation_followsSameBarbellRule() {
        let ex = exercise(equipment: .barbell, exerciseType: .isolation)
        let weight = WorkoutSessionEngine.defaultStartingWeight(for: ex, equipmentInventory: inventory(barbellWeight: 45))
        XCTAssertEqual(weight, 45)
    }

    // MARK: - logSet

    func test_logSet_firstSet_startsAtSetNumberOne() {
        var states: [UUID: ExerciseSessionState] = [:]
        let exerciseID = UUID()
        states[exerciseID] = ExerciseSessionState(
            targetReps: 10,
            workingWeightPounds: 100
        )

        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)

        XCTAssertEqual(states[exerciseID]?.loggedSets.count, 1)
        XCTAssertEqual(states[exerciseID]?.loggedSets.first?.setNumber, 1)
        XCTAssertEqual(states[exerciseID]?.loggedSets.first?.weight, 100)
        XCTAssertEqual(states[exerciseID]?.loggedSets.first?.reps, 10)
    }

    func test_logSet_subsequentSets_incrementSetNumber() {
        var states: [UUID: ExerciseSessionState] = [:]
        let exerciseID = UUID()
        states[exerciseID] = ExerciseSessionState(targetReps: 8, workingWeightPounds: 100)

        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)
        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)
        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)

        let setNumbers = states[exerciseID]?.loggedSets.map(\.setNumber)
        XCTAssertEqual(setNumbers, [1, 2, 3])
    }

    func test_logSet_missingState_createsDefaultState() {
        var states: [UUID: ExerciseSessionState] = [:]
        let exerciseID = UUID()

        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)

        XCTAssertEqual(states[exerciseID]?.loggedSets.count, 1)
    }

    // MARK: - deleteSet

    func test_deleteSet_removesSetAndRenumbersRemaining() {
        var states: [UUID: ExerciseSessionState] = [:]
        let exerciseID = UUID()
        states[exerciseID] = ExerciseSessionState(
            targetReps: 10,
            workingWeightPounds: 100
        )

        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)
        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)
        WorkoutSessionEngine.logSet(for: exerciseID, in: &states)

        let firstSetID = states[exerciseID]!.loggedSets[0].id
        WorkoutSessionEngine.deleteSet(setID: firstSetID, for: exerciseID, in: &states)

        let remaining = states[exerciseID]?.loggedSets
        XCTAssertEqual(remaining?.count, 2)
        XCTAssertEqual(remaining?.map(\.setNumber), [1, 2])
    }

    func test_deleteSet_missingExercise_doesNothing() {
        var states: [UUID: ExerciseSessionState] = [:]
        let exerciseID = UUID()

        WorkoutSessionEngine.deleteSet(setID: UUID(), for: exerciseID, in: &states)

        XCTAssertNil(states[exerciseID])
    }

    // MARK: - completedExercises / workoutLog

    func test_completedExercises_excludesExercisesWithNoLoggedSets() {
        let benched = exercise(name: "Bench Press")
        let squats = exercise(name: "Squat")
        let workout = Workout(name: "Push Day", exercises: [benched, squats])

        var states: [UUID: ExerciseSessionState] = [:]
        states[benched.id] = ExerciseSessionState(targetReps: 10, workingWeightPounds: 100, loggedSets: [
            LoggedSet(setNumber: 1, weight: 100, reps: 10)
        ])
        // squats has no logged sets at all

        let completed = WorkoutSessionEngine.completedExercises(for: workout, states: states)

        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.exerciseName, "Bench Press")
    }

    func test_workoutLog_noCompletedExercises_returnsNil() {
        let squats = exercise(name: "Squat")
        let workout = Workout(name: "Leg Day", exercises: [squats])

        let log = WorkoutSessionEngine.workoutLog(
            for: workout,
            states: [:],
            durationSeconds: 600
        )

        XCTAssertNil(log)
    }

    func test_workoutLog_withCompletedExercises_producesLogWithCorrectMetadata() {
        let benched = exercise(name: "Bench Press")
        let workout = Workout(name: "Push Day", exercises: [benched])

        var states: [UUID: ExerciseSessionState] = [:]
        states[benched.id] = ExerciseSessionState(targetReps: 10, workingWeightPounds: 135, loggedSets: [
            LoggedSet(setNumber: 1, weight: 135, reps: 10)
        ])

        let log = WorkoutSessionEngine.workoutLog(
            for: workout,
            states: states,
            durationSeconds: 1800
        )

        XCTAssertEqual(log?.workoutName, "Push Day")
        XCTAssertEqual(log?.durationSeconds, 1800)
        XCTAssertEqual(log?.completedExercises.count, 1)
        XCTAssertEqual(log?.completedExercises.first?.exerciseName, "Bench Press")
    }

    // MARK: - initialState

    func test_initialState_noHistory_usesDefaultStartingWeightAndMessage() {
        let ex = exercise(equipment: .barbell, exerciseType: .compound)

        let state = WorkoutSessionEngine.initialState(
            for: ex,
            latestPerformance: nil,
            previousPerformances: [],
            equipmentInventory: inventory(barbellWeight: 45)
        )

        XCTAssertEqual(state.targetReps, 10)
        XCTAssertEqual(state.workingWeightPounds, 45)
        XCTAssertEqual(state.suggestionMessage, "No history yet")
        XCTAssertTrue(state.loggedSets.isEmpty)
    }

    func test_initialState_withHistory_usesProgressionSuggestion() {
        let ex = exercise(equipment: .barbell, exerciseType: .compound, strategy: .doubleProgression)

        let latest = CompletedExercise(
            exerciseName: "Bench Press",
            sets: [
                LoggedSet(setNumber: 1, weight: 100, reps: 12),
                LoggedSet(setNumber: 2, weight: 100, reps: 12),
                LoggedSet(setNumber: 3, weight: 100, reps: 12)
            ],
            notes: ""
        )

        let state = WorkoutSessionEngine.initialState(
            for: ex,
            latestPerformance: latest,
            previousPerformances: [],
            equipmentInventory: inventory(barbellWeight: 45)
        )

        // All sets hit max reps (12), so double progression should suggest an increase.
        XCTAssertEqual(state.workingWeightPounds, 105)
        XCTAssertEqual(state.targetReps, 12)
        XCTAssertEqual(state.suggestionMessage, "Increase next time")
    }

    func test_initialState_noHistory_usesTemplateTargetWeightOverDefault() {
        let ex = exercise(
            equipment: .barbell,
            exerciseType: .compound,
            targetWeightPounds: 135
        )

        let state = WorkoutSessionEngine.initialState(
            for: ex,
            latestPerformance: nil,
            previousPerformances: [],
            equipmentInventory: inventory(barbellWeight: 45)
        )

        XCTAssertEqual(state.workingWeightPounds, 135)
    }

    func test_initialState_withHistory_ignoresTemplateTargetWeight() {
        let ex = exercise(
            equipment: .barbell,
            exerciseType: .compound,
            strategy: .doubleProgression,
            targetWeightPounds: 225
        )

        let latest = CompletedExercise(
            exerciseName: "Bench Press",
            sets: [
                LoggedSet(setNumber: 1, weight: 100, reps: 12),
                LoggedSet(setNumber: 2, weight: 100, reps: 12),
                LoggedSet(setNumber: 3, weight: 100, reps: 12)
            ],
            notes: ""
        )

        let state = WorkoutSessionEngine.initialState(
            for: ex,
            latestPerformance: latest,
            previousPerformances: [],
            equipmentInventory: inventory(barbellWeight: 45)
        )

        // Real progression history takes priority over the template's
        // one-time starting weight — 105 (progressed from 100), not 225.
        XCTAssertEqual(state.workingWeightPounds, 105)
    }

    // MARK: - shouldStartRest (supersets)

    func test_shouldStartRest_ungroupedExercise_alwaysStartsRest() {
        let ex = exercise(name: "Bench Press")
        let workout = Workout(name: "Push", exercises: [ex])

        XCTAssertTrue(
            WorkoutSessionEngine.shouldStartRest(after: ex, in: workout, states: [:])
        )
    }

    /// `first` just logged the round's opening set (its own turn); the
    /// round isn't complete until `second` also logs one, so this must
    /// not start rest yet.
    func test_shouldStartRest_notCompletingTheRound_doesNotStartRest() {
        let groupID = UUID()

        var first = exercise(name: "Bench Press")
        first.supersetGroupID = groupID

        var second = exercise(name: "Incline Row")
        second.supersetGroupID = groupID

        let workout = Workout(name: "Push", exercises: [first, second])

        let states: [UUID: ExerciseSessionState] = [
            first.id: ExerciseSessionState(loggedSets: [
                LoggedSet(setNumber: 1, weight: 135, reps: 8)
            ]),
            second.id: ExerciseSessionState(loggedSets: [])
        ]

        XCTAssertFalse(
            WorkoutSessionEngine.shouldStartRest(after: first, in: workout, states: states)
        )
    }

    /// `second` logging brings both members to 1 set each — the round is
    /// now complete, so this is the log that should start rest.
    func test_shouldStartRest_completingTheRound_startsRest() {
        let groupID = UUID()

        var first = exercise(name: "Bench Press")
        first.supersetGroupID = groupID

        var second = exercise(name: "Incline Row")
        second.supersetGroupID = groupID

        let workout = Workout(name: "Push", exercises: [first, second])

        let states: [UUID: ExerciseSessionState] = [
            first.id: ExerciseSessionState(loggedSets: [
                LoggedSet(setNumber: 1, weight: 135, reps: 8)
            ]),
            second.id: ExerciseSessionState(loggedSets: [
                LoggedSet(setNumber: 1, weight: 25, reps: 12)
            ])
        ]

        XCTAssertTrue(
            WorkoutSessionEngine.shouldStartRest(after: second, in: workout, states: states)
        )
    }

    func test_shouldStartRest_threeExerciseGroup_onlyLastTurnStartsRest() {
        let groupID = UUID()

        var first = exercise(name: "Bench Press")
        first.supersetGroupID = groupID

        var second = exercise(name: "Incline Row")
        second.supersetGroupID = groupID

        var third = exercise(name: "Face Pull")
        third.supersetGroupID = groupID

        let workout = Workout(name: "Push", exercises: [first, second, third])

        let afterFirst: [UUID: ExerciseSessionState] = [
            first.id: ExerciseSessionState(loggedSets: [LoggedSet(setNumber: 1, weight: 135, reps: 8)]),
            second.id: ExerciseSessionState(loggedSets: []),
            third.id: ExerciseSessionState(loggedSets: [])
        ]
        let afterSecond: [UUID: ExerciseSessionState] = [
            first.id: ExerciseSessionState(loggedSets: [LoggedSet(setNumber: 1, weight: 135, reps: 8)]),
            second.id: ExerciseSessionState(loggedSets: [LoggedSet(setNumber: 1, weight: 25, reps: 12)]),
            third.id: ExerciseSessionState(loggedSets: [])
        ]
        let afterThird: [UUID: ExerciseSessionState] = [
            first.id: ExerciseSessionState(loggedSets: [LoggedSet(setNumber: 1, weight: 135, reps: 8)]),
            second.id: ExerciseSessionState(loggedSets: [LoggedSet(setNumber: 1, weight: 25, reps: 12)]),
            third.id: ExerciseSessionState(loggedSets: [LoggedSet(setNumber: 1, weight: 60, reps: 15)])
        ]

        XCTAssertFalse(WorkoutSessionEngine.shouldStartRest(after: first, in: workout, states: afterFirst))
        XCTAssertFalse(WorkoutSessionEngine.shouldStartRest(after: second, in: workout, states: afterSecond))
        XCTAssertTrue(WorkoutSessionEngine.shouldStartRest(after: third, in: workout, states: afterThird))
    }

    func test_shouldStartRest_unrelatedGroupsDoNotInterfere() {
        let groupA = UUID()
        let groupB = UUID()

        var first = exercise(name: "Bench Press")
        first.supersetGroupID = groupA

        var second = exercise(name: "Incline Row")
        second.supersetGroupID = groupB

        var third = exercise(name: "Face Pull")
        third.supersetGroupID = groupB

        let workout = Workout(name: "Push", exercises: [first, second, third])

        // first is the only member of groupA, so every one of its own
        // logs trivially completes its (one-member) round.
        let firstLogsAlone: [UUID: ExerciseSessionState] = [
            first.id: ExerciseSessionState(loggedSets: [LoggedSet(setNumber: 1, weight: 135, reps: 8)])
        ]
        XCTAssertTrue(WorkoutSessionEngine.shouldStartRest(after: first, in: workout, states: firstLogsAlone))

        let afterSecond: [UUID: ExerciseSessionState] = [
            second.id: ExerciseSessionState(loggedSets: [LoggedSet(setNumber: 1, weight: 25, reps: 12)]),
            third.id: ExerciseSessionState(loggedSets: [])
        ]
        XCTAssertFalse(WorkoutSessionEngine.shouldStartRest(after: second, in: workout, states: afterSecond))

        let afterThird: [UUID: ExerciseSessionState] = [
            second.id: ExerciseSessionState(loggedSets: [LoggedSet(setNumber: 1, weight: 25, reps: 12)]),
            third.id: ExerciseSessionState(loggedSets: [LoggedSet(setNumber: 1, weight: 60, reps: 15)])
        ]
        XCTAssertTrue(WorkoutSessionEngine.shouldStartRest(after: third, in: workout, states: afterThird))
    }

    // MARK: - restTimerAnchorExerciseID

    func test_restTimerAnchorExerciseID_ungroupedExercise_anchorsOnItself() {
        let ex = exercise(name: "Bench Press")
        let workout = Workout(name: "Push", exercises: [ex])

        XCTAssertEqual(
            WorkoutSessionEngine.restTimerAnchorExerciseID(for: ex, in: workout),
            ex.id
        )
    }

    /// Regression test: rest between superset rounds is "time until the
    /// round starts again," and the round restarts at the group's first
    /// exercise — the badge should anchor there, not on the last member
    /// (the one that just triggered rest by finishing the round).
    func test_restTimerAnchorExerciseID_groupedExercise_anchorsOnFirstGroupMember() {
        let groupID = UUID()

        var first = exercise(name: "Bench Press")
        first.supersetGroupID = groupID

        var second = exercise(name: "Incline Row")
        second.supersetGroupID = groupID

        let workout = Workout(name: "Push", exercises: [first, second])

        XCTAssertEqual(
            WorkoutSessionEngine.restTimerAnchorExerciseID(for: second, in: workout),
            first.id
        )
        XCTAssertEqual(
            WorkoutSessionEngine.restTimerAnchorExerciseID(for: first, in: workout),
            first.id
        )
    }

    func test_restTimerAnchorExerciseID_noActiveWorkout_anchorsOnExerciseItself() {
        let ex = exercise(name: "Bench Press")

        XCTAssertEqual(
            WorkoutSessionEngine.restTimerAnchorExerciseID(for: ex, in: nil),
            ex.id
        )
    }

    // MARK: - canLogNextSet / nextSupersetExercise (superset round-robin)

    func test_canLogNextSet_ungroupedExercise_alwaysAllowed() {
        let ex = exercise(name: "Bench Press")

        XCTAssertTrue(
            WorkoutSessionEngine.canLogNextSet(for: ex, in: [ex], states: [:])
        )
    }

    /// Regression test: without this rule, logging exercise A's set 1
    /// immediately exposed A's set 2 as available, letting the user race
    /// ahead through A's whole working-set list before ever touching B —
    /// defeating the point of a superset.
    func test_canLogNextSet_memberAheadOfSibling_isBlocked() {
        let groupID = UUID()

        var first = exercise(name: "Bench Press")
        first.supersetGroupID = groupID

        var second = exercise(name: "Incline Row")
        second.supersetGroupID = groupID

        let states: [UUID: ExerciseSessionState] = [
            first.id: ExerciseSessionState(loggedSets: [
                LoggedSet(setNumber: 1, weight: 135, reps: 8)
            ]),
            second.id: ExerciseSessionState(loggedSets: [])
        ]

        XCTAssertFalse(
            WorkoutSessionEngine.canLogNextSet(for: first, in: [first, second], states: states)
        )
        XCTAssertTrue(
            WorkoutSessionEngine.canLogNextSet(for: second, in: [first, second], states: states)
        )
    }

    /// Regression test for the bug this milestone fixed: previously, a tie
    /// let *either* member go next, which meant a member could take two
    /// turns in a row purely because nothing forced the other member's
    /// turn first — and a later catch-up set from the sibling could then
    /// look like it completed a round that was never actually alternated
    /// (see `WorkoutSessionEngineTests.test_shouldStartRest_*`, and the
    /// on-device report that rest kept restarting mid-superset). Strict
    /// rotation means a tie resolves to exactly one exercise — whichever
    /// is next in `exercises` order — not both.
    func test_canLogNextSet_tiedForTheRound_onlyNextInRotationAllowed() {
        let groupID = UUID()

        var first = exercise(name: "Bench Press")
        first.supersetGroupID = groupID

        var second = exercise(name: "Incline Row")
        second.supersetGroupID = groupID

        let states: [UUID: ExerciseSessionState] = [
            first.id: ExerciseSessionState(loggedSets: [
                LoggedSet(setNumber: 1, weight: 135, reps: 8)
            ]),
            second.id: ExerciseSessionState(loggedSets: [
                LoggedSet(setNumber: 1, weight: 25, reps: 12)
            ])
        ]

        // Both tied at 1 set each — total logged (2) cycles back to
        // `first`'s turn, not `second`'s, even though they're tied.
        XCTAssertTrue(
            WorkoutSessionEngine.canLogNextSet(for: first, in: [first, second], states: states)
        )
        XCTAssertFalse(
            WorkoutSessionEngine.canLogNextSet(for: second, in: [first, second], states: states)
        )
    }

    /// Regression test: group members don't have to share the same
    /// `targetSets`. Without excluding a finished member from the
    /// round's minimum, a partner with more sets would freeze forever the
    /// moment the shorter member finished — the "minimum" would be
    /// permanently pinned at the finished member's final count, which the
    /// partner can never step back down to. Here `first` has only 2
    /// target sets and finishes first; `second` (4 target sets) must still
    /// be able to log its 3rd and 4th sets afterward.
    func test_canLogNextSet_shorterMemberFinishes_longerMemberContinuesUnblocked() {
        let groupID = UUID()

        var first = exercise(name: "Bench Press")
        first.supersetGroupID = groupID
        first.targetSets = 2

        var second = exercise(name: "Incline Row")
        second.supersetGroupID = groupID
        second.targetSets = 4

        // `first` has already logged both of its sets; `second` is only
        // on its 3rd.
        let states: [UUID: ExerciseSessionState] = [
            first.id: ExerciseSessionState(loggedSets: [
                LoggedSet(setNumber: 1, weight: 135, reps: 8),
                LoggedSet(setNumber: 2, weight: 135, reps: 8)
            ]),
            second.id: ExerciseSessionState(loggedSets: [
                LoggedSet(setNumber: 1, weight: 25, reps: 12),
                LoggedSet(setNumber: 2, weight: 25, reps: 12)
            ])
        ]

        XCTAssertTrue(
            WorkoutSessionEngine.canLogNextSet(for: second, in: [first, second], states: states),
            "second should be free to log its 3rd set once first has finished, not stuck waiting on a partner with nothing left to log"
        )
        XCTAssertNil(
            WorkoutSessionEngine.nextSupersetExercise(after: second, in: [first, second], states: states),
            "a finished member should never be pointed to as who to do next"
        )
    }

    func test_nextSupersetExercise_ungroupedExercise_isNil() {
        let ex = exercise(name: "Bench Press")

        XCTAssertNil(
            WorkoutSessionEngine.nextSupersetExercise(after: ex, in: [ex], states: [:])
        )
    }

    func test_nextSupersetExercise_memberAheadOfSibling_pointsToTheLaggingSibling() {
        let groupID = UUID()

        var first = exercise(name: "Bench Press")
        first.supersetGroupID = groupID

        var second = exercise(name: "Incline Row")
        second.supersetGroupID = groupID

        let states: [UUID: ExerciseSessionState] = [
            first.id: ExerciseSessionState(loggedSets: [
                LoggedSet(setNumber: 1, weight: 135, reps: 8)
            ]),
            second.id: ExerciseSessionState(loggedSets: [])
        ]

        XCTAssertEqual(
            WorkoutSessionEngine.nextSupersetExercise(after: first, in: [first, second], states: states)?.id,
            second.id
        )
        XCTAssertNil(
            WorkoutSessionEngine.nextSupersetExercise(after: second, in: [first, second], states: states)
        )
    }

    // MARK: - newPersonalRecords

    func test_newPersonalRecords_heavierSet_isReportedAsNewRecord() {
        let exerciseID = UUID()

        let priorLog = WorkoutLog(
            workoutName: "Push Day",
            date: Date(timeIntervalSinceNow: -86_400),
            completedExercises: [
                CompletedExercise(
                    exerciseID: exerciseID,
                    exerciseName: "Bench Press",
                    sets: [LoggedSet(setNumber: 1, weight: 100, reps: 8)],
                    notes: ""
                )
            ]
        )

        let newLog = WorkoutLog(
            workoutName: "Push Day",
            date: Date(),
            completedExercises: [
                CompletedExercise(
                    exerciseID: exerciseID,
                    exerciseName: "Bench Press",
                    sets: [LoggedSet(setNumber: 1, weight: 105, reps: 8)],
                    notes: ""
                )
            ]
        )

        let records = WorkoutSessionEngine.newPersonalRecords(
            in: newLog,
            priorLogs: [priorLog]
        )

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.weightPounds, 105)
    }

    /// Regression test for the identity-keying bug fixed alongside this
    /// test: grouping by `exerciseName` instead of the exercise's stable
    /// `id` would silently lose the connection between a custom exercise's
    /// history and itself the moment the exercise was renamed, since the
    /// name captured on each historical `CompletedExercise` never changes
    /// but the live exercise's name does. Keying by `exerciseID` — stable
    /// across a rename — must keep the old PR visible as the bar to beat
    /// even though the exercise's current name differs from the one on
    /// the historical log entry.
    func test_newPersonalRecords_afterExerciseRename_stillComparesAgainstPriorBestByID() {
        let exerciseID = UUID()

        let priorLog = WorkoutLog(
            workoutName: "Push Day",
            date: Date(timeIntervalSinceNow: -86_400),
            completedExercises: [
                CompletedExercise(
                    exerciseID: exerciseID,
                    exerciseName: "My Curl",
                    sets: [LoggedSet(setNumber: 1, weight: 20, reps: 10)],
                    notes: ""
                )
            ]
        )

        // The exercise was renamed after the prior log was written, but
        // `exerciseID` on the new log's entry is still the same stable id.
        let matchingWeightAfterRename = WorkoutLog(
            workoutName: "Push Day",
            date: Date(),
            completedExercises: [
                CompletedExercise(
                    exerciseID: exerciseID,
                    exerciseName: "My Bicep Curl",
                    sets: [LoggedSet(setNumber: 1, weight: 20, reps: 10)],
                    notes: ""
                )
            ]
        )

        let records = WorkoutSessionEngine.newPersonalRecords(
            in: matchingWeightAfterRename,
            priorLogs: [priorLog]
        )

        // Tying the prior best (not beating it) must NOT be reported as a
        // new record — this only holds if the prior log was actually found
        // and compared against, i.e. the rename didn't orphan the history.
        XCTAssertTrue(records.isEmpty)
    }
}
