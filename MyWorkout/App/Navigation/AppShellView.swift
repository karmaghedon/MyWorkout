import SwiftUI

struct AppShellView: View {
    @EnvironmentObject private var logStore: WorkoutLogStore
    @EnvironmentObject private var templateStore: WorkoutTemplateStore
    @EnvironmentObject private var customExerciseStore: CustomExerciseStore
    @EnvironmentObject private var activeWorkoutStore: ActiveWorkoutStore
    @EnvironmentObject private var settingsStore: UserSettingsStore

    @State private var selectedTab: AppTab = .home

    @State private var homePath: [AppRoute] = []
    @State private var libraryPath: [AppRoute] = []
    @State private var workoutPath: [AppRoute] = []
    @State private var progressPath: [AppRoute] = []
    @State private var profilePath: [AppRoute] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            appTab(
                .home,
                path: $homePath
            ) {
                DashboardView(
                    onStartWorkout: {
                        handleTabSelection(.workout)
                    }
                )
            }

            appTab(
                .library,
                path: $libraryPath
            ) {
                ExerciseLibraryView()
            }

            appTab(
                .workout,
                path: $workoutPath
            ) {
                StartWorkoutView()
            }

            appTab(
                .progress,
                path: $progressPath
            ) {
                ProgressHubView()
            }

            appTab(
                .profile,
                path: $profilePath
            ) {
                ProfileHubView()
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MyWorkoutTabBar(
                selection: selectedTab,
                workoutPresentation:
                    workoutTabPresentation,
                onSelect: handleTabSelection
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onChange(
            of: activeWorkoutStore.hasActiveWorkout
        ) { _, hasActiveWorkout in
            guard !hasActiveWorkout else {
                return
            }

            workoutPath.removeAll {
                $0 == .activeWorkout
            }
        }
        .preferredColorScheme(preferredColorScheme)
    }

    // MARK: - Appearance

    private var preferredColorScheme: ColorScheme? {
        switch settingsStore.settings.appearanceMode {
        case .system:
            nil

        case .light:
            .light

        case .dark:
            .dark
        }
    }

    // MARK: - Stateful Workout Destination

    private var workoutTabPresentation:
        WorkoutTabPresentation {
        guard activeWorkoutStore.hasActiveWorkout else {
            return .inactive
        }

        return .active(
            restSecondsRemaining:
                activeWorkoutStore.restSecondsRemaining
        )
    }

    private func handleTabSelection(
        _ tab: AppTab
    ) {
        guard tab == .workout else {
            selectedTab = tab
            return
        }

        selectedTab = .workout

        guard activeWorkoutStore.hasActiveWorkout else {
            return
        }

        routeToActiveWorkout()
    }

    private func routeToActiveWorkout() {
        guard workoutPath.last != .activeWorkout else {
            return
        }

        workoutPath = [.activeWorkout]
    }

    // MARK: - Tab Container

    private func appTab<Content: View>(
        _ tab: AppTab,
        path: Binding<[AppRoute]>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack(path: path) {
            content()
                .navigationDestination(
                    for: AppRoute.self
                ) { route in
                    destination(
                        for: route,
                        path: path
                    )
                }
        }
        .tabItem {
            AppTabLabel(tab: tab)
        }
        .tag(tab)
    }

    // MARK: - Route Resolution

    @ViewBuilder
    private func destination(
        for route: AppRoute,
        path: Binding<[AppRoute]>
    ) -> some View {
        switch route {
        case .startWorkout:
            StartWorkoutView()

        case .history:
            HistoryView()

        case .analytics:
            AnalyticsView()

        case .strengthTrends:
            StrengthTrendView()

        case .templates:
            TemplatesView()

        case .equipmentInventory:
            EquipmentInventoryView()

        case .settings:
            SettingsView()

        case .export:
            ExportView()

        case .activeWorkout:
            WorkoutSessionView()

        case let .workoutLogDetail(logID):
            if let log = logStore.logs.first(
                where: { $0.id == logID }
            ) {
                WorkoutLogDetailView(log: log)
            } else {
                missingDestinationView(
                    title: "Workout Not Found",
                    message:
                        "This workout may have been deleted."
                )
            }

        case let .editTemplate(templateID):
            if let template =
                    templateStore.templates.first(
                        where: { $0.id == templateID }
                    ) {
                TemplateEditorView(template: template)
                    .id(template.id)
            } else {
                missingDestinationView(
                    title: "Template Not Found",
                    message:
                        "This workout template may have "
                        + "been deleted."
                )
            }

        case let .exerciseDetail(exerciseID):
            if let exercise =
                    exerciseRegistry.exercise(
                        id: exerciseID
                    ) {
                ExerciseDetailView(exercise: exercise)
            } else {
                missingDestinationView(
                    title: "Exercise Not Found",
                    message:
                        "This exercise is no longer "
                        + "available."
                )
            }

        case .customExercises:
            CustomExercisesView(
                onCreateExercise: {
                    path.wrappedValue.append(
                        .createCustomExercise
                    )
                },
                onEditExercise: { exercise in
                    path.wrappedValue.append(
                        .editCustomExercise(
                            exercise.id
                        )
                    )
                }
            )

        case .createCustomExercise:
            CustomExerciseFormView(
                mode: .create
            )

        case let .editCustomExercise(exerciseID):
            if let exercise =
                    customExerciseStore.exercise(
                        id: exerciseID
                    ) {
                CustomExerciseFormView(
                    mode: .edit(exercise)
                )
            } else {
                missingDestinationView(
                    title: "Exercise Not Found",
                    message:
                        "This custom exercise may have "
                        + "been archived or removed."
                )
            }
        }
    }

    private var exerciseRegistry: ExerciseRegistry {
        ExerciseRegistryFactory.make(
            templates: templateStore.templates,
            logs: logStore.logs,
            customExercises:
                customExerciseStore.allExercises
        )
    }

    private func missingDestinationView(
        title: String,
        message: String
    ) -> some View {
        AppEmptyStateView(
            title: LocalizedStringKey(title),
            message: LocalizedStringKey(message),
            systemImage:
                "exclamationmark.triangle"
        )
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
