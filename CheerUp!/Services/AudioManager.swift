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
