import AVFoundation

/// Synthesizes a short bell tone from scratch — additive synthesis: a
/// handful of sine partials at the *inharmonic* frequency ratios real
/// bells produce (not clean integer multiples of the fundamental, which
/// is what makes a struck bell sound different from a plucked string),
/// each with its own independent exponential decay so the higher,
/// brighter partials die out first and the tone visibly darkens as it
/// rings down.
///
/// Exists because this app's rest-timer alert options are otherwise
/// limited to iOS's built-in system sounds (classic ones addressable by
/// numeric ID, real named ones like "Cosmic"/"Radar" unreachable — their
/// files live under a system path this app's sandbox can't read on
/// current iOS) — none of which included a convincing bell. Rendering
/// one directly sidesteps that catalog entirely.
enum BellSynthesizer {
    /// Kept alive for the duration of playback — an `AVAudioEngine`/
    /// `AVAudioPlayerNode` pair torn down immediately after `play()`
    /// returns would never actually produce sound.
    private static var engine: AVAudioEngine?
    private static var player: AVAudioPlayerNode?

    private struct Partial {
        let ratio: Double
        let amplitude: Double
        let decay: Double
    }

    /// Frequency ratios and per-partial decay rates modeled loosely on
    /// how a small, bright (silvery, not gong-like) bell actually rings:
    /// an inharmonic spread rather than a clean harmonic series, with
    /// higher partials both quieter and faster-decaying than the
    /// fundamental.
    private static let partials: [Partial] = [
        Partial(ratio: 1.0, amplitude: 1.0, decay: 1.8),
        Partial(ratio: 2.0, amplitude: 0.55, decay: 2.6),
        Partial(ratio: 2.4, amplitude: 0.45, decay: 3.4),
        Partial(ratio: 3.0, amplitude: 0.32, decay: 4.2),
        Partial(ratio: 4.2, amplitude: 0.18, decay: 6.0),
        Partial(ratio: 5.4, amplitude: 0.10, decay: 8.0)
    ]

    private static let fundamentalHz = 1_046.5 // C6 — bright/"silver", not a dull low toll
    private static let sampleRate = 44_100.0
    /// Per-strike length — shorter than a single strike's natural full
    /// decay would ring out to, so three of these queued back-to-back
    /// (~3s total) land as three distinct, evenly-spaced dings rather
    /// than one long, faded-out note repeated with awkward gaps.
    private static let durationSeconds = 1.0
    private static let strikeCount = 3

    /// Rings the bell `strikeCount` times — the same rendered buffer
    /// queued repeatedly, which `AVAudioPlayerNode` plays back-to-back
    /// in the order scheduled. One strike alone was too brief to
    /// register as a "the timer went off" cue.
    static func play() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = renderedBuffer(format: format) else { return }

        // `AVAudioEngine.start()` activates the shared audio session
        // under whatever category is currently set — left unconfigured,
        // that defaults to `.soloAmbient`, which silences whatever else
        // is already playing (Spotify, Apple Music, a podcast app) for
        // as long as this engine is running. `.ambient` with
        // `.mixWithOthers` is the category actually meant for a short
        // incidental sound effect layered over other apps' audio: it
        // leaves other playback running, still respects the silent
        // switch (consistent with this app's other rest-timer sound
        // options, which are plain system sounds).
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true, options: [])

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            return
        }

        // Hold references before scheduling — `player.play()` below can
        // otherwise race the completion handler on a very short buffer.
        Self.engine = engine
        Self.player = player

        for strike in 0..<strikeCount {
            let isLastStrike = strike == strikeCount - 1

            player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in
                guard isLastStrike else { return }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    engine.stop()
                    if Self.engine === engine {
                        Self.engine = nil
                        Self.player = nil
                    }
                }
            }
        }

        player.play()
    }

    private static func renderedBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }

        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate

            let sample = partials.reduce(into: 0.0) { total, partial in
                let frequency = fundamentalHz * partial.ratio
                let envelope = exp(-partial.decay * time)
                total += partial.amplitude * envelope * sin(2 * .pi * frequency * time)
            }

            // Partial amplitudes sum to ~2.6 at t=0 — scaled down well
            // clear of clipping (a bell's transient strike attack would
            // otherwise distort at full scale).
            channel[frame] = Float(sample * 0.18)
        }

        return buffer
    }
}
