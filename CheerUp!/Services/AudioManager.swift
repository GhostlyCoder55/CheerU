import AVFoundation

// MARK: - Audio Manager
// High-quality sound effects powered by Kenney Audio (CC0 1.0 Universal / Public Domain).
// Pre-loads audio buffers with AVAudioPlayer for zero-latency instant playback.

final class AudioManager {
    static let shared = AudioManager()

    private static let enabledKey = "cheerup.sound.enabled"
    private var _isEnabled: Bool
    private(set) var isEnabled: Bool {
        get { _isEnabled }
        set {
            _isEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
        }
    }

    private var players: [SoundEffect: [AVAudioPlayer]] = [:]
    private let playerPoolSize = 3 // Allows overlapping fast taps
    private let audioQueue = DispatchQueue(label: "com.gc.cheerup.audiomanager", qos: .userInitiated)

    private init() {
        if UserDefaults.standard.object(forKey: Self.enabledKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.enabledKey)
            _isEnabled = true
        } else {
            _isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        }

        // Configure audio session and preload audio buffers off the main thread to prevent UI hitches
        audioQueue.async { [weak self] in
            self?.configureAudioSession()
            self?.preloadSounds()
        }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    // MARK: - Sound Effects

    enum SoundEffect: String, CaseIterable {
        case tap = "tap"
        case pop = "pop"
        case switchToggle = "switch"
        case switchOff = "switch_off"
        case bounce = "bounce"
        case error = "error"
        case nextLevel = "next_level"
        case combo = "combo"
        case win = "win"
        case ding = "ding"
        case slimeStick = "slime_stick"
        case successTrumpet = "success_trumpet"
    }

    /// Play a sound effect from the pre-loaded Kenney audio pool asynchronously off the main thread
    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }

        audioQueue.async { [weak self] in
            guard let self = self else { return }

            // Find an idle player in the pool, or reuse the first
            if let pool = self.players[effect], !pool.isEmpty {
                for player in pool {
                    if !player.isPlaying {
                        player.currentTime = 0
                        player.play()
                        return
                    }
                }
                // All busy, replay first
                let player = pool[0]
                player.currentTime = 0
                player.play()
            }
        }
    }

    // MARK: - Preloading

    private func preloadSounds() {
        // Preload fast disk-backed gameplay SFX first so taps/bounces are ready immediately on launch,
        // then synthesize heavier procedural fanfares/bells in the background.
        let diskEffects = SoundEffect.allCases.filter { $0 != .ding && $0 != .slimeStick && $0 != .successTrumpet }
        let synthEffects: [SoundEffect] = [.slimeStick, .ding, .successTrumpet]

        for effect in diskEffects {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav", subdirectory: "Sounds")
                    ?? Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else {
                continue
            }

            var pool: [AVAudioPlayer] = []
            pool.reserveCapacity(playerPoolSize)
            for _ in 0..<playerPoolSize {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    player.volume = 0.85
                    pool.append(player)
                }
            }
            players[effect] = pool
        }

        for effect in synthEffects {
            if let (wavData, targetVolume) = Self.synthesizedAudio(for: effect), let wavData {
                var pool: [AVAudioPlayer] = []
                pool.reserveCapacity(playerPoolSize)
                for _ in 0..<playerPoolSize {
                    if let player = try? AVAudioPlayer(data: wavData) {
                        player.prepareToPlay()
                        player.volume = targetVolume
                        pool.append(player)
                    }
                }
                players[effect] = pool
            }
        }
    }

    /// Synthesizes a clean metallic desk-bell / kitchen-timer "Ding!" with resonant harmonics
    private static func makeClockDingWAV() -> Data? {
        let sampleRate = 44100
        let duration = 0.95
        let totalSamples = Int(duration * Double(sampleRate))
        var pcm = [Int16](repeating: 0, count: totalSamples)

        let fundamental = 1567.98 // G6 bell pitch
        let overtone1   = 3135.96 // 2x harmonic
        let overtone2   = 4318.00 // Metallic bell chime partial

        for i in 0..<totalSamples {
            let t = Double(i) / Double(sampleRate)
            // Instant crisp strike attack (2ms) followed by natural bell ring decay
            let attack = min(1.0, t / 0.002)
            let env1 = exp(-t * 4.8)
            let env2 = exp(-t * 10.5)
            let env3 = exp(-t * 22.0)

            let s1 = sin(2.0 * .pi * fundamental * t) * env1 * 0.62
            let s2 = sin(2.0 * .pi * overtone1 * t) * env2 * 0.25
            let s3 = sin(2.0 * .pi * overtone2 * t) * env3 * 0.13

            let sample = (s1 + s2 + s3) * attack * 0.85
            pcm[i] = Int16(max(-32767.0, min(32767.0, sample * 32767.0)))
        }

        return makeMono16WAV(pcm: pcm, sampleRate: sampleRate)
    }

    /// Synthesizes a tactile wet slime/sticky "squelch + suction bloop" sound when the ball sticks to the paddle.
    private static func makeSlimeStickWAV() -> Data? {
        let sampleRate = 44100
        let duration = 0.19
        let totalSamples = Int(duration * Double(sampleRate))
        var pcm = [Int16](repeating: 0, count: totalSamples)

        var phaseMain = 0.0
        var phaseBubble = 0.0
        var noiseState: UInt64 = 0x5EEDBEEF12345678
        var lpFilter = 0.0

        for i in 0..<totalSamples {
            let t = Double(i) / Double(sampleRate)
            let norm = t / duration
            let attack = min(1.0, t / 0.004)
            let tailFade = norm > 0.72 ? max(0.0, 1.0 - (norm - 0.72) / 0.28) : 1.0

            // 1. Primary gooey impact compression then sticky suction pull-up (340 Hz -> 145 Hz -> 330 Hz)
            let mainFreq: Double
            if t < 0.045 {
                let u = t / 0.045
                mainFreq = 340.0 - 195.0 * u
            } else {
                let u = min(1.0, (t - 0.045) / 0.115)
                mainFreq = 145.0 + 185.0 * (u * u)
            }
            phaseMain += 2.0 * .pi * mainFreq / Double(sampleRate)
            let squishEnv = exp(-t * 14.0) * 0.72

            // 2. Wet suction bubble bloop peaking around 55ms..145ms
            let bubbleT = max(0.0, t - 0.052)
            let bubbleFreq = 220.0 + 360.0 * min(1.0, bubbleT / 0.085)
            phaseBubble += 2.0 * .pi * bubbleFreq / Double(sampleRate)
            let bubbleWindow = t >= 0.052 ? sin(min(1.0, bubbleT / 0.10) * .pi) : 0.0
            let bubble = sin(phaseBubble) * bubbleWindow * 0.45

            // 3. Modulated low-pass wet squelch noise
            noiseState = noiseState &* 6364136223846793005 &+ 1442695040888963407
            let white = Double(Int64(bitPattern: noiseState) >> 32) / Double(Int32.max)
            // Deterministic 1-pole low-pass (~1 kHz) modulated by sticky ripple
            lpFilter += 0.13 * (white - lpFilter)
            let ripple = 0.5 + 0.5 * sin(2.0 * .pi * 48.0 * t)
            let squelch = lpFilter * exp(-t * 20.0) * ripple * 0.48

            let raw = (sin(phaseMain) * squishEnv + bubble + squelch) * attack * tailFade
            let sample = tanh(raw * 1.15) * 0.90
            pcm[i] = Int16(max(-32767.0, min(32767.0, sample * 32767.0)))
        }

        return makeMono16WAV(pcm: pcm, sampleRate: sampleRate)
    }

    private static func synthesizedAudio(for effect: SoundEffect) -> (Data?, Float)? {
        switch effect {
        case .ding:           return (makeClockDingWAV(), 0.9)
        case .slimeStick:     return (makeSlimeStickWAV(), 0.95)
        case .successTrumpet: return (makeSuccessTrumpetWAV(), 0.92)
        default:              return nil
        }
    }

    /// Synthesizes a bright, short 4-note brass trumpet fanfare (C5-E5-G5-C6) for completed challenges.
    private static func makeSuccessTrumpetWAV() -> Data? {
        let sampleRate = 44100
        let duration = 0.78
        let totalSamples = Int(duration * Double(sampleRate))
        var pcm = [Int16](repeating: 0, count: totalSamples)

        // (startSec, endSec, frequencyHz, isSustainedFinal)
        let notes: [(Double, Double, Double, Bool)] = [
            (0.00, 0.11, 523.25, false),  // C5
            (0.11, 0.22, 659.25, false),  // E5
            (0.22, 0.34, 783.99, false),  // G5
            (0.34, 0.78, 1046.50, true)   // C6 triumph hold
        ]

        var phase = 0.0
        for i in 0..<totalSamples {
            let t = Double(i) / Double(sampleRate)
            guard let note = notes.first(where: { t >= $0.0 && t < $0.1 }) else { continue }

            let noteT = t - note.0
            let noteLen = note.1 - note.0
            let attack = min(1.0, noteT / 0.012)
            let releaseLen = note.3 ? 0.14 : 0.025
            let release = min(1.0, max(0.0, (note.1 - t) / releaseLen))
            let decay = note.3 ? exp(-noteT * 2.2) : exp(-noteT * 5.0)

            // Crisp brass tongue scoop at note onset + gentle vibrato on final held note
            let onsetScoop = 1.0 - 0.025 * exp(-noteT * 90.0)
            let vibrato = note.3 ? (1.0 + 0.004 * sin(2.0 * .pi * 5.8 * noteT) * min(1.0, noteT / 0.15)) : 1.0
            let freq = note.2 * onsetScoop * vibrato
            phase += 2.0 * .pi * freq / Double(sampleRate)

            // Trumpet harmonic spectrum (bright upper partials blooming cleanly after attack)
            let brassBloom = min(1.0, noteT / 0.022)
            let h1 = sin(phase) * 0.48
            let h2 = sin(phase * 2.0) * 0.30 * (0.65 + 0.35 * brassBloom)
            let h3 = sin(phase * 3.0) * 0.19 * brassBloom
            let h4 = sin(phase * 4.0) * 0.11 * brassBloom * exp(-noteT * 4.0)
            let h5 = sin(phase * 5.0) * 0.06 * brassBloom * exp(-noteT * 6.5)

            let env = attack * release * decay * (noteLen > 0 ? 1.0 : 0.0)
            let sample = tanh((h1 + h2 + h3 + h4 + h5) * env * 1.1) * 0.88
            pcm[i] = Int16(max(-32767.0, min(32767.0, sample * 32767.0)))
        }

        return makeMono16WAV(pcm: pcm, sampleRate: sampleRate)
    }

    private static func makeMono16WAV(pcm: [Int16], sampleRate: Int) -> Data? {
        guard !pcm.isEmpty else { return nil }
        let dataSize = pcm.count * 2
        let fileSize = 36 + dataSize
        var header = Data()

        func u32(_ v: UInt32) -> Data { var le = v.littleEndian; return Data(bytes: &le, count: 4) }
        func u16(_ v: UInt16) -> Data { var le = v.littleEndian; return Data(bytes: &le, count: 2) }

        header.append(Data("RIFF".utf8))
        header.append(u32(UInt32(fileSize)))
        header.append(Data("WAVE".utf8))
        header.append(Data("fmt ".utf8))
        header.append(u32(16))
        header.append(u16(1))
        header.append(u16(1))
        header.append(u32(UInt32(sampleRate)))
        header.append(u32(UInt32(sampleRate * 2)))
        header.append(u16(2))
        header.append(u16(16))
        header.append(Data("data".utf8))
        header.append(u32(UInt32(dataSize)))

        pcm.withUnsafeBufferPointer { ptr in
            if let base = ptr.baseAddress {
                header.append(UnsafeBufferPointer(
                    start: UnsafeRawPointer(base).assumingMemoryBound(to: UInt8.self),
                    count: dataSize
                ))
            }
        }
        return header
    }

    private func configureAudioSession() {
        do {
            // Ambient category mixes with background music and respects the silent switch
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Audio session configuration failed, continue without sound
        }
    }
}
