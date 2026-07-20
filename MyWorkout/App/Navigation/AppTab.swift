import SwiftUI

enum AppTab: Hashable, CaseIterable, Identifiable {
    case home
    case library
    case workout
    case progress
    case profile

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .home:
            "Home"
        case .library:
            "Library"
        case .workout:
            "Workout"
        case .progress:
            "Progress"
        case .profile:
            "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .library:
            "books.vertical"
        case .workout:
            "figure.strengthtraining.traditional"
        case .progress:
            "chart.line.uptrend.xyaxis"
        case .profile:
            "person.crop.circle"
        }
    }

    var selectedSystemImage: String {
        switch self {
        case .home:
            "house.fill"
        case .library:
            "books.vertical.fill"
        case .workout:
            "figure.strengthtraining.traditional"
        case .progress:
            "chart.line.uptrend.xyaxis"
        case .profile:
            "person.crop.circle.fill"
        }
    }

    var accessibilityLabel: LocalizedStringKey {
        switch self {
        case .home:
            "Home"
        case .library:
            "Exercise Library"
        case .workout:
            "Workout"
        case .progress:
            "Progress and History"
        case .profile:
            "Profile and Settings"
        }
    }

    var isPrimaryDestination: Bool {
        self == .workout
    }
}
