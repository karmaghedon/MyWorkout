import Foundation

/// One stop on the live app tour: which tab to switch to, what the
/// tab's navigation path should be once there (almost always empty —
/// every step today targets a tab's root hub/list rather than pushing
/// into a detail screen), and which `.tourAnchor(_:)`-registered view
/// to spotlight once that screen is showing.
struct TourStep: Identifiable, Equatable {
    let id: String
    let tab: AppTab
    let path: [AppRoute]
    let anchorID: String
    let title: String
    let message: String
}

extension TourStep {
    /// One step per major capability area rather than every sub-screen
    /// — a guided overview of what the app can do, not an exhaustive
    /// click-through of every route. See `Docs/Features/Tour.md`.
    static let all: [TourStep] = [
        TourStep(
            id: "home-hero",
            tab: .home,
            path: [],
            anchorID: "home-hero",
            title: "Start a Workout",
            message: "Resume a workout already in progress, or start your next one straight from this card — it always suggests whichever template is most overdue."
        ),
        TourStep(
            id: "home-week",
            tab: .home,
            path: [],
            anchorID: "home-week-summary",
            title: "This Week",
            message: "See this week's workout and set counts at a glance, and tap any day to log a weigh-in or nutrition entry for that date."
        ),
        TourStep(
            id: "home-log-weight",
            tab: .home,
            path: [],
            anchorID: "home-log-weight",
            title: "Log Weight",
            message: "Track body weight, body fat %, waist, and neck from here — used for body-fat estimates and your weekly report."
        ),
        TourStep(
            id: "home-nutrition",
            tab: .home,
            path: [],
            anchorID: "home-nutrition",
            title: "Today's Nutrition",
            message: "Keep an eye on today's calories and macros against your goal, and tap in to log a meal."
        ),
        TourStep(
            id: "library-browse",
            tab: .library,
            path: [],
            anchorID: "library-browse",
            title: "Find an Exercise",
            message: "Search by name or narrow down to a body part — the library covers barbell, dumbbell, bodyweight, and band movements for every muscle group."
        ),
        TourStep(
            id: "library-custom",
            tab: .library,
            path: [],
            anchorID: "library-custom",
            title: "Add Your Own",
            message: "Can't find a movement you do? Add a custom exercise here with its own muscle groups, equipment, and progression settings."
        ),
        TourStep(
            id: "workout-templates-list",
            tab: .workout,
            path: [],
            anchorID: "workout-templates-list",
            title: "Start a Workout",
            message: "Pick a template to start logging sets — the app tracks warm-ups and rest timers, and suggests your next working weight automatically."
        ),
        TourStep(
            id: "workout-manage-templates",
            tab: .workout,
            path: [],
            anchorID: "workout-manage-templates",
            title: "Build Your Templates",
            message: "Create and edit templates here — working weights, rep ranges, supersets, and per-exercise warm-up/progression overrides."
        ),
        TourStep(
            id: "progress-overview",
            tab: .progress,
            path: [],
            anchorID: "progress-overview",
            title: "History & Analytics",
            message: "Browse every past workout, see your personal records and training volume, and track estimated one-rep-max trends over time."
        ),
        TourStep(
            id: "progress-body",
            tab: .progress,
            path: [],
            anchorID: "progress-body",
            title: "Body Trends",
            message: "Weekly weight/body-fat/waist/neck summaries, plus a combined chart to spot trends across every body metric at once."
        ),
        TourStep(
            id: "profile-settings",
            tab: .profile,
            path: [],
            anchorID: "profile-settings",
            title: "Settings",
            message: "Switch units, pick a rest-timer sound, choose your workout session layout, and set your strength formula here."
        ),
        TourStep(
            id: "profile-macro-goals",
            tab: .profile,
            path: [],
            anchorID: "profile-macro-goals",
            title: "Macro Goals",
            message: "Set a daily calorie and macro target — Today's Nutrition on Home tracks your progress against it."
        ),
        TourStep(
            id: "profile-equipment",
            tab: .profile,
            path: [],
            anchorID: "profile-equipment",
            title: "Equipment",
            message: "Tell the app which plates, dumbbells, and barbells you actually have — it's used to suggest real loadable warm-up and working weights."
        ),
        TourStep(
            id: "profile-backup",
            tab: .profile,
            path: [],
            anchorID: "profile-backup",
            title: "Backup & Data",
            message: "Export your workout history to CSV, or back up and restore everything in the app."
        )
    ]
}
