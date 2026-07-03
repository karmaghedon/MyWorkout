import Foundation
#if os(iOS)
import UIKit
#endif

/// Thin wrapper around UIKit's haptic feedback generators so call sites
/// don't need `#if os(iOS)` guards scattered through the view layer.
/// Every function is a no-op on macOS, where haptic feedback isn't available.
enum Haptics {
    /// A quick, tactile confirmation for a discrete, user-initiated action —
    /// e.g. logging a set.
    static func setLogged() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    /// A "something finished successfully" cue for events that complete on
    /// their own, without a direct tap — e.g. the rest timer running out.
    static func restComplete() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}
