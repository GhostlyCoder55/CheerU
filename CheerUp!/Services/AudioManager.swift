import AVFoundation

// MARK: - Audio Manager
// High-quality sound effects powered by Kenney Audio (CC0 1.0 Universal / Public Domain).
// Pre-loads audio buffers with AVAudioPlayer for zero-latency instant playback.

final class AudioManager {
    static let shared = AudioManager()

    private(set) var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "cheerup.sound.enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "cheerup.sound.enabled") }
    }

    private var players: [SoundEffect: [AVAudioPlayer]] = [:]
    private let playerPoolSize = 3 // Allows overlapping fast taps

    private init() {
        if UserDefaults.standard.object(forKey: "cheerup.sound.enabled") == nil {
            UserDefaults.standard.set(true, forKey: "cheerup.sound.enabled")
        }

        configureAudioSession()
        preloadSounds()
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
    }

    /// Play a sound effect from the pre-loaded Kenney audio pool
    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }

        // Find an idle player in the pool, or reuse the first
        if let pool = players[effect], !pool.isEmpty {
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

    // MARK: - Preloading

    private func preloadSounds() {
        for effect in SoundEffect.allCases {
            if effect == .ding {
                if let dingData = Self.makeClockDingWAV() {
                    var pool: [AVAudioPlayer] = []
                    for _ in 0..<playerPoolSize {
                        if let player = try? AVAudioPlayer(data: dingData) {
                            player.prepareToPlay()
                            player.volume = 0.9
                            pool.append(player)
                        }
                    }
                    players[.ding] = pool
                }
                continue
            }

            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav", subdirectory: "Sounds")
                    ?? Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else {
                continue
            }

            var pool: [AVAudioPlayer] = []
            for _ in 0..<playerPoolSize {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    player.volume = 0.85
                    pool.append(player)
                }
            }
            players[effect] = pool
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
            header.append(UnsafeBufferPointer(
                start: UnsafeRawPointer(ptr.baseAddress!)?.assumingMemoryBound(to: UInt8.self),
                count: dataSize
            ))
        }
        return header
    }

    private func configureAudioSession() {
        do {
            // Ambient category mixes with background music and respects the silent switch
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session configuration failed — continue without sound
        }
    }
}
