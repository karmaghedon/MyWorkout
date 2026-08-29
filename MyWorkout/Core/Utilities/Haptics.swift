import AudioToolbox
import Foundation
import UIKit
/// Thin wrapper around UIKit's haptic feedback generators.
enum Haptics {
    /// A short, built-in system alert tone. Used instead of a bundled sound
    /// asset — the project isn't set up to register new bundle resources
    /// safely in this environment, and this ID has been a stable,
    /// widely-used "short chime" cue since early iOS.
    private static let restCompleteSoundID: SystemSoundID = 1016

    /// A quick, tactile confirmation for a discrete, user-initiated action —
    /// e.g. logging a set.
    static func setLogged() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// A "something finished successfully" cue for events that complete on
    /// their own, without a direct tap — e.g. the rest timer running out.
    /// Pairs a haptic (silent if the user has System Haptics off) with a
    /// short system sound (silent if the phone is on Silent/muted), so the
    /// cue is felt or heard depending on the user's own settings.
    static func restComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        AudioServicesPlaySystemSound(restCompleteSoundID)
    }
}
