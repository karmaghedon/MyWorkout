import AudioToolbox
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
    /// Pairs a haptic (silent if the user has System Haptics off) with
    /// `sound` (silent if the phone is on Silent/muted, or if the user
    /// picked "Off"), so the cue is felt or heard depending on the user's
    /// own settings.
    static func restComplete(sound: RestTimerSound) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        play(sound)
    }

    /// Plays `sound` on its own, with no haptic — used by the Settings
    /// picker so you can preview an option before choosing it.
    static func preview(_ sound: RestTimerSound) {
        play(sound)
    }

    private static func play(_ sound: RestTimerSound) {
        if sound == .silverBell {
            BellSynthesizer.play()
        } else if let soundID = sound.systemSoundID {
            AudioServicesPlaySystemSound(soundID)
        }
    }
}

extension RestTimerSound {
    /// Built-in system alert tone IDs — stable, widely-used short-alert
    /// cues since early iOS, addressed by a plain numeric ID via the
    /// classic `AudioServicesPlaySystemSound` catalog. Used instead of a
    /// bundled sound asset — the project isn't set up to register new
    /// bundle resources safely in this environment. `.none` and
    /// `.silverBell` (synthesized — see `BellSynthesizer`) don't use
    /// this catalog at all.
    var systemSoundID: SystemSoundID? {
        switch self {
        case .none, .silverBell: return nil
        case .triTone: return 1013
        case .trumpet: return 1025
        case .digital: return 1005
        }
    }
}
