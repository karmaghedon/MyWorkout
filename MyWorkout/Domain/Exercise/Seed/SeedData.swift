import Foundation

struct SeedData {

    static let exercises: [Exercise] = [
        exercise(
            "Bench Press",
            muscleGroup: .chest,
            equipment: .barbell,
            instructions: """
            1. Lie on the bench with your eyes under the bar.
            2. Grip slightly wider than shoulder width.
            3. Pull shoulder blades back and down.
            4. Lower the bar under control to the lower chest.
            5. Press up without bouncing.
            """
        ),

        exercise(
            "Front Squat",
            muscleGroup: .legs,
            equipment: .barbell,
            instructions: """
            1. Place the bar across the front shoulders.
            2. Keep elbows high and chest tall.
            3. Brace before each rep.
            4. Squat down with knees tracking over toes.
            5. Drive through mid-foot to stand.
            """
        ),

        exercise(
            "Romanian Deadlift",
            muscleGroup: .hamstrings ,
            equipment: .barbell,
            instructions: """
            1. Stand tall with the bar in front of thighs.
            2. Keep knees slightly bent.
            3. Push hips backward while keeping back neutral.
            4. Lower until you feel hamstrings stretch.
            5. Drive hips forward to stand.
            """
        ),

        exercise(
            "Incline Bench Press",
            muscleGroup: .chest,
            equipment: .dumbbell,
            instructions: """
            1. Set bench to a low or moderate incline.
            2. Start with dumbbells at chest level.
            3. Keep shoulder blades pulled back.
            4. Press up under control.
            5. Lower slowly without shoulders rolling forward.
            """
        ),

        exercise(
            "Incline Row",
            muscleGroup: .back,
            equipment: .dumbbell,
            instructions: """
            1. Lie chest-down on an incline bench.
            2. Let dumbbells hang straight down.
            3. Pull elbows back toward hips.
            4. Squeeze shoulder blades.
            5. Lower slowly without shrugging.
            """
        ),

        exercise(
            "Bent Over Row - Underhand",
            muscleGroup: .back,
            equipment: .barbell,
            instructions: """
            1. Hold the bar with palms facing up.
            2. Hinge at hips with a neutral spine.
            3. Pull the bar toward lower ribs.
            4. Keep elbows close.
            5. Lower under control.
            """
        ),

        exercise(
            "Pull Up",
            muscleGroup: .back,
            equipment: .bodyweight,
            instructions: """
            1. Grip bar with palms facing away.
            2. Start from a controlled hang.
            3. Pull shoulder blades down.
            4. Drive elbows toward ribs.
            5. Lower slowly without swinging.
            """,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Chin Up",
            muscleGroup: .back,
            equipment: .bodyweight,
            instructions: """
            1. Grip bar with palms facing you.
            2. Start from a controlled hang.
            3. Pull elbows down toward sides.
            4. Bring chin above bar if possible.
            5. Lower slowly with control.
            """,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Chest Dip",
            muscleGroup: .chest,
            equipment: .bodyweight,
            instructions: """
            1. Support yourself on parallel bars.
            2. Keep shoulders down.
            3. Lean slightly forward.
            4. Lower under control.
            5. Press back up without bouncing.
            """,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Strict Military Press",
            muscleGroup: .shoulders,
            equipment: .barbell,
            instructions: """
            1. Start with bar at upper chest.
            2. Brace core and squeeze glutes.
            3. Press bar overhead.
            4. Move head slightly back, then through.
            5. Avoid leaning backward.
            """
        ),

        exercise(
            "Glute Bridge",
            muscleGroup: .glutes,
            equipment: .barbell,
            instructions: """
            1. Lie on back with knees bent.
            2. Place bar across hips if using weight.
            3. Drive through heels.
            4. Squeeze glutes at the top.
            5. Avoid over-arching lower back.
            """
        ),

        exercise(
            "Goblet Squat",
            muscleGroup: .legs,
            equipment: .kettlebellOrDumbbell,
            instructions: """
            1. Hold weight close to chest.
            2. Stand with feet about shoulder width.
            3. Brace core.
            4. Squat with knees tracking over toes.
            5. Stand through mid-foot.
            """
        ),

        exercise(
            "Inverted Row",
            muscleGroup: .back,
            equipment: .bodyweight,
            instructions: """
            1. Set a bar around waist height.
            2. Lie underneath and grip the bar.
            3. Keep body straight.
            4. Pull chest toward bar.
            5. Lower slowly.
            """,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Face Pull",
            muscleGroup: .shoulders,
            equipment: .cableOrBand,
            instructions: """
            1. Set band or cable at face height.
            2. Pull toward your face.
            3. Keep elbows high.
            4. Squeeze rear delts and upper back.
            5. Return slowly.
            """,
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Skullcrusher",
            muscleGroup: .triceps,
            equipment: .barbell,
            instructions: """
            1. Lie on bench with bar above chest.
            2. Keep upper arms mostly still.
            3. Bend elbows and lower bar carefully.
            4. Extend elbows to raise bar.
            5. Start light to protect elbows.
            """,
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Triceps Extension",
            muscleGroup: .triceps,
            equipment: .barbell,
            instructions: """
            1. Hold bar with comfortable grip.
            2. Keep upper arms steady.
            3. Lower weight by bending elbows.
            4. Extend elbows under control.
            5. Avoid swinging.
            """,
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Bicep Curl",
            muscleGroup: .biceps,
            equipment: .barbell,
            instructions: """
            1. Stand tall with palms facing up.
            2. Keep elbows close to sides.
            3. Curl without swinging.
            4. Lower slowly.
            5. Stop if elbow or forearm pain appears.
            """,
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Hammer Curl",
            muscleGroup: .biceps,
            equipment: .dumbbell,
            instructions: """
            1. Hold dumbbells with palms facing each other.
            2. Keep elbows close.
            3. Curl without swinging.
            4. Lower slowly.
            5. Stop if forearm pain appears.
            """,
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        // MARK: - Barbell

        exercise(
            "Conventional Deadlift",
            muscleGroup: .back,
            equipment: .barbell,
            instructions: """
            1. Stand with feet hip-width apart, bar over mid-foot.
            2. Hinge down and grip the bar just outside your legs.
            3. Brace your core, flatten your back, and pull the slack out of the bar.
            4. Drive through your heels, keeping the bar close to your legs as hips and shoulders rise together.
            5. Lock out by squeezing your glutes, then reverse the motion under control.
            """,
            primaryMuscles: ["Erector Spinae", "Glutes", "Hamstrings"],
            secondaryMuscles: ["Lats", "Traps", "Forearms"],
            difficulty: "Advanced",
            tips: [
                "Keep the bar in contact with your shins and thighs throughout the pull.",
                "Take a full breath and brace before each rep."
            ],
            commonMistakes: [
                "Rounding the lower back instead of hinging at the hips.",
                "Letting the bar drift away from the body."
            ],
            warnings: [
                "Stop the set if you feel your lower back rounding under load.",
                "Start light and add weight gradually to groove the pattern before loading heavy."
            ],
            minReps: 5,
            maxReps: 8
        ),

        exercise(
            "Barbell Back Squat",
            muscleGroup: .quadriceps,
            equipment: .barbell,
            instructions: """
            1. Set the bar across your upper traps and unrack it with feet shoulder-width apart.
            2. Brace your core and keep your chest tall.
            3. Bend your hips and knees together, tracking knees over your toes.
            4. Descend until your thighs are at least parallel to the floor.
            5. Drive through your whole foot to stand back up.
            """,
            primaryMuscles: ["Quadriceps", "Glutes"],
            secondaryMuscles: ["Hamstrings", "Core"],
            difficulty: "Advanced",
            tips: [
                "Keep your eyes forward and chest up to maintain a neutral spine.",
                "Push your knees out in line with your toes on the way down."
            ],
            commonMistakes: [
                "Letting the knees cave inward.",
                "Rising onto the balls of the feet instead of driving through the whole foot."
            ],
            warnings: [
                "Use a rack with safety bars (or a spotter) when working near your limit.",
                "If you can't hit depth with control, reduce the weight before adding more."
            ],
            minReps: 5,
            maxReps: 8
        ),

        exercise(
            "Barbell Hip Thrust",
            muscleGroup: .glutes,
            equipment: .barbell,
            instructions: """
            1. Sit on the ground with your upper back against a bench, barbell over your hips (use a pad).
            2. Plant feet flat, shins roughly vertical.
            3. Brace your core and tuck your ribs down before driving up.
            4. Drive through your heels until hips are fully extended and knees are at about 90 degrees.
            5. Squeeze your glutes at the top, then lower under control.
            """,
            primaryMuscles: ["Glutes"],
            secondaryMuscles: ["Hamstrings", "Core"],
            difficulty: "Intermediate",
            tips: [
                "Keep your chin tucked and ribs down to avoid over-arching your lower back.",
                "Pause and squeeze your glutes hard at the top of every rep."
            ],
            commonMistakes: [
                "Hyperextending the lower back instead of driving through the hips.",
                "Placing feet too close or too far from the body, losing power."
            ],
            warnings: [
                "Use a hip thrust pad or folded mat — the bar can be uncomfortable on the hips otherwise.",
                "Add weight gradually; the loaded top position is easy to lose control of if you jump up too fast."
            ],
            minReps: 8,
            maxReps: 12
        ),

        exercise(
            "Barbell Bent Over Row - Overhand",
            muscleGroup: .back,
            equipment: .barbell,
            instructions: """
            1. Hold the bar with palms facing down, just outside shoulder width.
            2. Hinge at the hips until your torso is close to parallel with the floor.
            3. Keep a neutral spine and let the bar hang at arm's length.
            4. Pull the bar toward your lower ribs, driving elbows back.
            5. Lower under control without losing your hip hinge.
            """,
            primaryMuscles: ["Lats", "Rhomboids", "Traps"],
            secondaryMuscles: ["Biceps", "Rear Delts"],
            difficulty: "Intermediate",
            tips: [
                "Keep your torso angle steady — don't stand up on each rep to cheat the weight.",
                "Pull with your elbows, not your hands."
            ],
            commonMistakes: [
                "Rounding the back to reach the bar.",
                "Using momentum to jerk the bar up."
            ],
            warnings: [
                "Stop if your lower back rounds — regress the weight rather than the position."
            ]
        ),

        exercise(
            "Close-Grip Bench Press",
            muscleGroup: .triceps,
            equipment: .barbell,
            instructions: """
            1. Lie on the bench with a grip about shoulder width, hands closer than a standard bench press.
            2. Unrack and hold the bar over your chest.
            3. Keep elbows tucked closer to your body as you lower the bar.
            4. Lower to your lower chest under control.
            5. Press up, focusing on extending through the elbows.
            """,
            primaryMuscles: ["Triceps"],
            secondaryMuscles: ["Chest", "Front Delts"],
            difficulty: "Intermediate",
            tips: [
                "Keep elbows tracking at roughly a 45-degree angle, not flared out.",
                "Squeeze the bar hard to help keep the shoulders stable."
            ],
            commonMistakes: [
                "Gripping too narrow, which stresses the wrists.",
                "Flaring elbows out like a standard bench press."
            ],
            warnings: [
                "Use a spotter or safety bars when pressing near your limit."
            ]
        ),

        // MARK: - Dumbbell

        exercise(
            "Dumbbell Shoulder Press",
            muscleGroup: .shoulders,
            equipment: .dumbbell,
            instructions: """
            1. Sit or stand holding dumbbells at shoulder height, palms facing forward.
            2. Brace your core and avoid arching your lower back.
            3. Press the dumbbells up until arms are extended overhead.
            4. Bring the dumbbells slightly together at the top without clanking them.
            5. Lower under control back to shoulder height.
            """,
            primaryMuscles: ["Front Delts", "Side Delts"],
            secondaryMuscles: ["Triceps", "Upper Chest"],
            difficulty: "Intermediate",
            tips: [
                "Brace your core to keep your ribs from flaring and your back from arching.",
                "Press slightly forward and up rather than straight up to clear your head."
            ],
            commonMistakes: [
                "Arching the lower back to gain range of motion.",
                "Flaring elbows out too wide at the bottom."
            ],
            warnings: [
                "Use a lighter weight if you feel shoulder pinching near lockout."
            ]
        ),

        exercise(
            "Dumbbell Lateral Raise",
            muscleGroup: .shoulders,
            equipment: .dumbbell,
            instructions: """
            1. Stand holding a light dumbbell in each hand at your sides, knees slightly bent.
            2. Lean your torso forward slightly.
            3. Raise the dumbbells out to the sides with a slight bend in the elbows until they reach shoulder height.
            4. Lead with your elbows, not your hands.
            5. Lower slowly back to your sides.
            """,
            primaryMuscles: ["Side Delts"],
            secondaryMuscles: ["Traps"],
            difficulty: "Beginner",
            tips: [
                "Keep the weight light — this is a shaping move, not a max-strength one.",
                "Stop raising at shoulder height; going higher shifts the work to your traps."
            ],
            commonMistakes: [
                "Swinging the weight up with momentum.",
                "Shrugging the shoulders up toward the ears."
            ],
            warnings: [
                "Stop if you feel pinching in the front of the shoulder — try raising slightly in front of your body instead of straight out to the side."
            ],
            minReps: 12,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Dumbbell Walking Lunge",
            muscleGroup: .legs,
            equipment: .dumbbell,
            instructions: """
            1. Hold a dumbbell in each hand at your sides.
            2. Step forward into a lunge, lowering your back knee toward the floor.
            3. Keep your front knee tracking over your foot, not caving in.
            4. Drive through your front heel to stand and step into the next lunge.
            5. Alternate legs as you walk forward.
            """,
            primaryMuscles: ["Quadriceps", "Glutes"],
            secondaryMuscles: ["Hamstrings", "Core"],
            difficulty: "Intermediate",
            tips: [
                "Take a long enough step that your front shin stays close to vertical at the bottom.",
                "Keep your torso upright rather than leaning forward."
            ],
            commonMistakes: [
                "Taking too short a step, driving the front knee past the toes.",
                "Letting the front knee collapse inward."
            ],
            warnings: [
                "Do this in a clear, open space — you'll need room to walk forward each set."
            ]
        ),

        exercise(
            "Bulgarian Split Squat",
            muscleGroup: .glutes,
            equipment: .dumbbell,
            instructions: """
            1. Stand a couple of feet in front of a bench, holding a dumbbell in each hand.
            2. Rest the top of one foot on the bench behind you.
            3. Lower straight down until your front knee is bent to about 90 degrees.
            4. Keep most of your weight on your front heel.
            5. Drive through the front foot to stand back up.
            """,
            primaryMuscles: ["Glutes", "Quadriceps"],
            secondaryMuscles: ["Hamstrings"],
            difficulty: "Intermediate",
            tips: [
                "Find the foot spacing where you can go straight down without your front knee sliding forward.",
                "Keep about 90% of your weight on the front leg."
            ],
            commonMistakes: [
                "Leaning too far forward, turning it into a hip-dominant movement.",
                "Placing the rear foot too high on a bench that's too tall."
            ],
            warnings: [
                "Use a low, stable surface if balance is limited — a fall from a tall bench is the main risk here."
            ]
        ),

        exercise(
            "Standing Calf Raise",
            muscleGroup: .calves,
            equipment: .dumbbell,
            instructions: """
            1. Hold a dumbbell in each hand, standing with the balls of your feet on a raised platform or step.
            2. Let your heels drop below the platform for a full stretch.
            3. Press through the balls of your feet to rise as high as possible.
            4. Pause briefly at the top.
            5. Lower slowly back to the stretched position.
            """,
            primaryMuscles: ["Calves"],
            difficulty: "Beginner",
            tips: [
                "Slow down the descent — 2-3 seconds down gets more out of the stretch.",
                "Keep your knees slightly soft rather than locked straight."
            ],
            commonMistakes: [
                "Bouncing through a short range of motion instead of going heel-to-toe.",
                "Using too little weight to make the exercise worthwhile."
            ],
            warnings: [
                "Hold onto something stable for balance if you're on an elevated step."
            ],
            minReps: 12,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Single-Arm Dumbbell Row",
            muscleGroup: .back,
            equipment: .dumbbell,
            instructions: """
            1. Place one knee and hand on a bench, other foot on the floor.
            2. Let the dumbbell hang straight down from a flat back.
            3. Pull the dumbbell up toward your hip, driving your elbow back.
            4. Squeeze your shoulder blade at the top.
            5. Lower under control without twisting your torso.
            """,
            primaryMuscles: ["Lats", "Rhomboids"],
            secondaryMuscles: ["Biceps", "Rear Delts"],
            difficulty: "Beginner",
            tips: [
                "Keep your back flat and roughly parallel to the floor throughout.",
                "Pull with your elbow, not your hand, to keep the back engaged."
            ],
            commonMistakes: [
                "Rotating the torso to help lift the weight.",
                "Using a bouncing motion instead of a controlled pull."
            ]
        ),

        exercise(
            "Dumbbell Thruster",
            muscleGroup: .fullBody,
            equipment: .dumbbell,
            instructions: """
            1. Hold a dumbbell in each hand at shoulder height, feet shoulder-width apart.
            2. Squat down until your thighs are at least parallel to the floor.
            3. Drive up explosively out of the squat.
            4. Use that upward momentum to press the dumbbells overhead.
            5. Lower the dumbbells back to your shoulders as you descend into the next rep.
            """,
            primaryMuscles: ["Quadriceps", "Shoulders"],
            secondaryMuscles: ["Glutes", "Triceps", "Core"],
            difficulty: "Intermediate",
            tips: [
                "Let the leg drive power the press — don't muscle it up with your shoulders alone.",
                "Keep your core braced through the transition from squat to press."
            ],
            commonMistakes: [
                "Pausing at the top of the squat instead of using it to drive the press.",
                "Losing squat depth as fatigue sets in."
            ],
            warnings: [
                "Start with lighter dumbbells until the timing of the squat-to-press transition feels smooth."
            ],
            minReps: 8,
            maxReps: 12
        ),

        // MARK: - Bodyweight

        exercise(
            "Push Up",
            muscleGroup: .chest,
            equipment: .bodyweight,
            instructions: """
            1. Set hands slightly wider than shoulder width, body in a straight line from head to heels.
            2. Brace your core and squeeze your glutes and quads.
            3. Lower your chest toward the floor with elbows tracking back at about 45 degrees.
            4. Stop just before your chest touches the ground.
            5. Press back up to a straight-arm plank.
            """,
            primaryMuscles: ["Chest", "Triceps"],
            secondaryMuscles: ["Front Delts", "Core"],
            difficulty: "Beginner",
            tips: [
                "Keep a straight line from head to heels throughout — think plank, not pike.",
                "If full reps break down, do them from an incline (hands on a bench) instead of dropping to your knees."
            ],
            commonMistakes: [
                "Letting the hips sag toward the floor.",
                "Flaring the elbows straight out to the sides."
            ],
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Hanging Leg Raise",
            muscleGroup: .core,
            equipment: .bodyweight,
            instructions: """
            1. Hang from a pull-up bar with arms fully extended.
            2. Brace your core and avoid swinging.
            3. Raise your legs (straight or bent) until they're at least parallel to the floor.
            4. Pause briefly at the top.
            5. Lower slowly back to a dead hang.
            """,
            primaryMuscles: ["Abs", "Hip Flexors"],
            secondaryMuscles: ["Forearms", "Lats"],
            difficulty: "Advanced",
            tips: [
                "Bend your knees to make it easier while you build the strength for straight-leg raises.",
                "Curl your pelvis under at the top rather than just swinging your legs up."
            ],
            commonMistakes: [
                "Using momentum to swing the legs up instead of controlled core work.",
                "Not going high enough to actually load the abs."
            ],
            warnings: [
                "Stop if you feel strain in your lower back rather than your abs — that usually means you're swinging."
            ],
            minReps: 8,
            maxReps: 12,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Sit-Up",
            muscleGroup: .core,
            equipment: .bodyweight,
            instructions: """
            1. Lie on your back with knees bent and feet flat on the floor.
            2. Cross your arms over your chest or place hands lightly behind your head.
            3. Curl your torso up off the floor until you're sitting upright.
            4. Squeeze your abs at the top without yanking on your neck.
            5. Lower back down under control.
            """,
            primaryMuscles: ["Abs"],
            secondaryMuscles: ["Hip Flexors"],
            difficulty: "Beginner",
            tips: [
                "Exhale as you curl up to help engage your abs.",
                "Keep the movement smooth rather than using a jerking motion to sit up."
            ],
            commonMistakes: [
                "Pulling on the neck with your hands instead of curling with your abs.",
                "Using momentum by swinging the arms."
            ],
            minReps: 12,
            maxReps: 20,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Burpee",
            muscleGroup: .fullBody,
            equipment: .bodyweight,
            instructions: """
            1. Start standing, then squat down and place your hands on the floor.
            2. Jump or step your feet back into a plank position.
            3. Perform a push-up (optional for beginners).
            4. Jump or step your feet back up to your hands.
            5. Explode upward into a jump, reaching arms overhead.
            """,
            primaryMuscles: ["Full Body"],
            secondaryMuscles: ["Cardiovascular System"],
            difficulty: "Intermediate",
            tips: [
                "Step feet back and forward instead of jumping if you want a lower-impact version.",
                "Keep your core braced during the plank/push-up phase so your hips don't sag."
            ],
            commonMistakes: [
                "Letting the hips sag during the plank/push-up phase.",
                "Landing the jump with locked knees."
            ],
            warnings: [
                "Land softly with bent knees to protect your joints, especially on hard floors."
            ],
            minReps: 8,
            maxReps: 15,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Step-Up",
            muscleGroup: .quadriceps,
            equipment: .bodyweight,
            instructions: """
            1. Stand facing a sturdy bench or box.
            2. Place one foot fully on the box.
            3. Drive through that foot to stand up on the box.
            4. Bring your other foot up to stand tall, then step back down under control.
            5. Alternate legs, or complete all reps on one side before switching.
            """,
            primaryMuscles: ["Quadriceps", "Glutes"],
            secondaryMuscles: ["Hamstrings", "Calves"],
            difficulty: "Beginner",
            tips: [
                "Push through the heel of the working leg rather than pushing off the trailing foot.",
                "Choose a box height where your knee doesn't pass much beyond your toes at the top."
            ],
            commonMistakes: [
                "Pushing off the bottom leg to help drive the movement instead of letting the top leg do the work.",
                "Using a box that's too high, forcing the knee to cave in."
            ],
            warnings: [
                "Use a box or bench that won't slide or tip.",
                "Hold onto a stable surface for balance if needed."
            ],
            minReps: 8,
            maxReps: 12,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        exercise(
            "Bodyweight Squat",
            muscleGroup: .quadriceps,
            equipment: .bodyweight,
            instructions: """
            1. Stand with feet shoulder-width apart, toes slightly turned out.
            2. Brace your core and keep your chest tall.
            3. Bend your hips and knees to lower down, keeping knees tracking over your toes.
            4. Go as low as you can while keeping your heels on the floor.
            5. Drive through your feet to stand back up.
            """,
            primaryMuscles: ["Quadriceps", "Glutes"],
            secondaryMuscles: ["Hamstrings", "Core"],
            difficulty: "Beginner",
            tips: [
                "Reach your arms forward for balance if you tip backward.",
                "Sit back and down, like lowering into a chair."
            ],
            commonMistakes: [
                "Letting the knees cave inward.",
                "Rising onto the toes instead of staying flat-footed."
            ],
            minReps: 12,
            maxReps: 20,
            exerciseType: .bodyweight,
            progressionStrategy: .bodyweightReps
        ),

        // MARK: - Band

        exercise(
            "Band Pull-Apart",
            muscleGroup: .shoulders,
            equipment: .cableOrBand,
            instructions: """
            1. Hold a resistance band with both hands, arms extended in front of you at shoulder height.
            2. Grip slightly wider than shoulder width.
            3. Pull the band apart by driving your hands out to the sides.
            4. Squeeze your shoulder blades together as the band reaches your chest.
            5. Return slowly to the starting position.
            """,
            primaryMuscles: ["Rear Delts", "Rhomboids"],
            secondaryMuscles: ["Traps"],
            difficulty: "Beginner",
            tips: [
                "Keep a slight bend in the elbows throughout, not locked straight.",
                "Use it as a warm-up before pressing movements to prime the upper back."
            ],
            commonMistakes: [
                "Bending the elbows to make the band easier to pull apart.",
                "Shrugging the shoulders up instead of squeezing them back."
            ],
            warnings: [
                "Inspect the band for tears before use — a snapped band can snap back toward the face."
            ],
            minReps: 12,
            maxReps: 20,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Band Deadlift",
            muscleGroup: .hamstrings,
            equipment: .cableOrBand,
            instructions: """
            1. Stand on the middle of the band with feet hip-width apart.
            2. Grip the ends or handles just outside your legs.
            3. Hinge at the hips, keeping your back flat as you bend down.
            4. Drive your hips forward to stand, squeezing your glutes and hamstrings.
            5. Lower back down under control by hinging at the hips again.
            """,
            primaryMuscles: ["Hamstrings", "Glutes"],
            secondaryMuscles: ["Erector Spinae"],
            difficulty: "Beginner",
            tips: [
                "Brace your core before each rep to keep your spine neutral.",
                "Keep the band under the middle of both feet so tension stays even."
            ],
            commonMistakes: [
                "Rounding the back instead of hinging at the hips.",
                "Standing on the band unevenly, causing it to slip."
            ],
            warnings: [
                "Check the band for wear before each use — a worn band can snap under tension."
            ],
            minReps: 10,
            maxReps: 15
        ),

        exercise(
            "Band Row",
            muscleGroup: .back,
            equipment: .cableOrBand,
            instructions: """
            1. Anchor the band at chest height or loop it around a sturdy post.
            2. Step back until there's tension, feet shoulder-width apart.
            3. Hold the handles with arms extended, palms facing each other.
            4. Pull your elbows back, squeezing your shoulder blades together.
            5. Return slowly to the starting position, resisting the band's pull.
            """,
            primaryMuscles: ["Lats", "Rhomboids"],
            secondaryMuscles: ["Biceps", "Rear Delts"],
            difficulty: "Beginner",
            tips: [
                "Keep your chest up and avoid leaning back to help pull the band.",
                "Control the return — don't let the band snap your arms forward."
            ],
            commonMistakes: [
                "Using the lower back to lean and pull instead of the arms and back.",
                "Not fully controlling the band on the way back."
            ],
            warnings: [
                "Make sure the anchor point is secure before loading the band."
            ],
            minReps: 10,
            maxReps: 15
        ),

        exercise(
            "Band Squat",
            muscleGroup: .quadriceps,
            equipment: .cableOrBand,
            instructions: """
            1. Stand on the band with feet shoulder-width apart, holding the ends at shoulder height.
            2. Brace your core and keep your chest tall.
            3. Bend your hips and knees to squat down, keeping tension on the band.
            4. Descend until your thighs are at least parallel to the floor.
            5. Drive through your feet to stand back up.
            """,
            primaryMuscles: ["Quadriceps", "Glutes"],
            secondaryMuscles: ["Hamstrings", "Core"],
            difficulty: "Beginner",
            tips: [
                "Stand on the band evenly with both feet to keep tension balanced.",
                "Increase resistance by using a thicker band or standing wider on it, not by rushing reps."
            ],
            commonMistakes: [
                "Letting the knees cave inward under band tension.",
                "Using a band too light to provide a real training stimulus."
            ],
            warnings: [
                "Check the band for damage before each use."
            ],
            minReps: 12,
            maxReps: 20
        ),

        exercise(
            "Band Bicep Curl",
            muscleGroup: .biceps,
            equipment: .cableOrBand,
            instructions: """
            1. Stand on the middle of the band with feet hip-width apart.
            2. Hold the handles with palms facing forward, arms extended down.
            3. Keep elbows pinned to your sides.
            4. Curl the handles up toward your shoulders.
            5. Lower slowly, resisting the band's pull back down.
            """,
            primaryMuscles: ["Biceps"],
            secondaryMuscles: ["Forearms"],
            difficulty: "Beginner",
            tips: [
                "Keep your upper arms still — only the forearms should move.",
                "Control the eccentric (lowering) phase instead of letting the band yank your arms down."
            ],
            commonMistakes: [
                "Swinging the torso to help curl the band up.",
                "Letting the elbows drift forward."
            ],
            minReps: 12,
            maxReps: 20,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Band Triceps Pushdown",
            muscleGroup: .triceps,
            equipment: .cableOrBand,
            instructions: """
            1. Anchor the band overhead (a door anchor or sturdy high point).
            2. Hold the handles with elbows bent and tucked at your sides.
            3. Keep upper arms still as you extend your elbows.
            4. Push the handles down until your arms are straight.
            5. Return slowly, resisting the band back to the bent position.
            """,
            primaryMuscles: ["Triceps"],
            difficulty: "Beginner",
            tips: [
                "Keep your elbows glued to your sides throughout the movement.",
                "Focus on a slow, controlled return rather than letting the band snap your arms back up."
            ],
            commonMistakes: [
                "Letting the elbows flare away from the body.",
                "Using the shoulders to help push instead of isolating the triceps."
            ],
            warnings: [
                "Make sure the overhead anchor is secure before loading the band."
            ],
            minReps: 12,
            maxReps: 20,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        ),

        exercise(
            "Band Woodchopper",
            muscleGroup: .core,
            equipment: .cableOrBand,
            instructions: """
            1. Anchor the band at about chest height to one side of you.
            2. Stand sideways to the anchor, feet shoulder-width apart, holding the handle with both hands.
            3. Rotate your torso and pull the band diagonally across your body.
            4. Pivot your back foot as you rotate, driving with your core, not just your arms.
            5. Return slowly to the starting position under control.
            """,
            primaryMuscles: ["Obliques", "Abs"],
            secondaryMuscles: ["Shoulders"],
            difficulty: "Intermediate",
            tips: [
                "Rotate from your torso and hips, not just your arms.",
                "Keep a slight bend in the knees for stability."
            ],
            commonMistakes: [
                "Using only the arms to pull the band instead of rotating through the core.",
                "Rushing the movement, which turns it into momentum rather than control."
            ],
            warnings: [
                "Check the band and anchor point for security before starting."
            ],
            minReps: 10,
            maxReps: 15,
            exerciseType: .isolation,
            progressionStrategy: .slowProgression
        )
    ]

    static let workouts: [Workout] = [
        Workout(name: "Workout A", exercises: workoutAExercises),
        Workout(name: "Workout B", exercises: workoutBExercises),
        Workout(name: "Workout C", exercises: workoutAExercises)
    ]

    static let defaultTemplates: [WorkoutTemplate] = [
        WorkoutTemplate(name: "Workout A", exercises: workoutAExercises),
        WorkoutTemplate(name: "Workout B", exercises: workoutBExercises)
    ]

    private static var workoutAExercises: [Exercise] {
        exercisesFor([
            "Front Squat",
            "Bench Press",
            "Incline Row",
            "Chin Up",
            "Chest Dip",
            "Glute Bridge",
            "Skullcrusher",
            "Bicep Curl",
            "Face Pull"
        ])
    }

    private static var workoutBExercises: [Exercise] {
        exercisesFor([
            "Romanian Deadlift",
            "Front Squat",
            "Incline Bench Press",
            "Incline Row",
            "Pull Up",
            "Strict Military Press",
            "Triceps Extension",
            "Hammer Curl"
        ])
    }

    private static func exercisesFor(_ names: [String]) -> [Exercise] {
        names.compactMap { name in
            exercises.first { $0.name == name }
        }
    }

    private static func exercise(
        _ name: String,
        muscleGroup: MuscleGroup,
        equipment: ExerciseEquipment,
        instructions: String,

        primaryMuscles: [String] = [],
        secondaryMuscles: [String] = [],
        difficulty: String = "Beginner",
        tips: [String] = [],
        commonMistakes: [String] = [],
        warnings: [String] = [],

        minReps: Int = 8,
        maxReps: Int = 10,
        increaseAmount: Double = 5,
        deloadAmount: Double = 5,
        stallLimit: Int = 3,
        exerciseType: ExerciseType = .compound,
        progressionStrategy: ProgressionStrategy = .doubleProgression
    ) -> Exercise {
        Exercise(
            name: name,
            muscleGroup: muscleGroup,
            equipment: equipment,
            instructions: instructions,

            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles,
            difficulty: difficulty,
            tips: tips,
            commonMistakes: commonMistakes,
            warnings: warnings,

            progressionRule: ProgressionRule(
                minReps: minReps,
                maxReps: maxReps,
                increaseAmount: increaseAmount,
                deloadAmount: deloadAmount,
                stallLimit: stallLimit
            ),
            exerciseType: exerciseType,
            progressionStrategy: progressionStrategy
        )
    }
}
