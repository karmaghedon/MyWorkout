import Foundation
import UIKit
/// Thin wrapper around UIKit's haptic feedback generators.
enum Haptics {
    /// A quick, tactile confirmation for a discrete, user-initiated action —
    /// e.g. logging a set.
    static func setLogged() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// A "something finished successfully" cue for events that complete on
    /// their own, without a direct tap — e.g. the rest timer running out.
    static func restComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
