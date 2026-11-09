import SwiftUI
import GameKit
import AVFoundation

// MARK: - RUSH Models & Types
// Data structures, Game Center integration, and retro synth audio for CheerUp! Arcade: RUSH.

struct RushMeteor: Identifiable, Equatable {
    static let collisionRadius: CGFloat = 21.0
    static let grazeRadius: CGFloat = 52.0

    let id: UUID = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var rotation: CGFloat
    var angularVelocity: CGFloat
    var hasGrantedNearMiss: Bool = false
    var hasPassedShip: Bool = false
}

// MARK: - Little Power Up Orbs (Shield & Slow Speed Only)

enum RushPowerUpType: String, CaseIterable, Identifiable {
    case shield   = "shield"
    case slowTime = "slowTime"

    var id: String { rawValue }

    var badgeTitle: String {
        switch self {
        case .shield:
            return LanguageManager.shared.tr("SHIELD ORB", "ORBE BOUCLIER", "ORBE ESCUDO")
        case .slowTime:
            return LanguageManager.shared.tr("SLOW ORB", "ORBE RALENTI", "ORBE LENTO")
        }
    }

    var duration: Double {
        switch self {
        case .shield:   return 12.0 // Or until absorbing 1 meteor hit
        case .slowTime: return 6.0  // Slows down meteor speed
        }
    }

    var color: Color {
        switch self {
        case .shield:   return Color(hex: 0x22D3EE) // Glowing Cyan Orb
        case .slowTime: return Color(hex: 0xA855F7) // Glowing Violet Orb
        }
    }

    var colorHex: UInt {
        switch self {
        case .shield:   return 0x22D3EE
        case .slowTime: return 0xA855F7
        }
    }
}

struct RushCollectible: Identifiable, Equatable {
    let id: UUID = UUID()
    let type: RushPowerUpType
    var x: CGFloat
    var y: CGFloat
    var vy: CGFloat
    var bobPhase: Double = 0.0
}

struct ActiveRushEffect: Identifiable, Equatable {
    var id: String { type.rawValue }
    let type: RushPowerUpType
    var remaining: Double
    let totalDuration: Double

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, remaining / totalDuration))
    }
}

// MARK: - Surprise Special Events

enum RushSpecialEventKind: String, CaseIterable, Equatable {
    case meteorShower // Wave of meteors with fair warning telegraph
    case twinGate     // Meteor row with a glowing safe corridor gap

    var warningText: String {
        switch self {
        case .meteorShower:
            return LanguageManager.shared.tr("METEOR WAVE INCOMING!", "VAGUE DE MÉTÉORES !", "¡OLA DE METEOROS!")
        case .twinGate:
            return LanguageManager.shared.tr("METEOR GATE AHEAD!", "PASSAGE DE MÉTÉORES !", "¡PUERTA DE METEOROS!")
        }
    }

    var colorHex: UInt {
        switch self {
        case .meteorShower: return 0xFF2E93
        case .twinGate:     return 0x22D3EE
        }
    }
}

enum RushEvent: Equatable {
    case scoreChanged(newScore: Int)
    case nearMiss(x: CGFloat, y: CGFloat, streak: Int)
    case powerUpCollected(RushPowerUpType, x: CGFloat, y: CGFloat)
    case shieldAbsorbedHit(x: CGFloat, y: CGFloat)
    case specialEventWarning(RushSpecialEventKind, safeCorridorX: CGFloat?)
    case specialEventStarted(RushSpecialEventKind)
    case gameOver(finalScore: Int, isNewBest: Bool, impactX: CGFloat, impactY: CGFloat)
}

// MARK: - Game Center Leaderboard Integration

final class RushGameCenterManager {
    static let shared = RushGameCenterManager()
    static let leaderboardID = "com.gc.CheerUp.rush.endless"

    private init() {}

    func submitScore(_ score: Int) {
        GameCenterManager.shared.submitScore(score, for: .rush)
    }
}

// MARK: - Rush Synthwave Chiptune Audio Controller

final class RushAudioController {
    static let shared = RushAudioController()

    private var bgmPlayer: AVAudioPlayer?
    private var nearMissPlayer: AVAudioPlayer?
    private var warningPlayer: AVAudioPlayer?
    private var shieldBreakPlayer: AVAudioPlayer?
    private let audioQueue = DispatchQueue(label: "com.gc.cheerup.rush.audio", qos: .userInitiated)

    private init() {
        // Synthesize retro audio buffers and prepare players off the main thread
        audioQueue.async { [weak self] in
            self?.buildSynthesizedAudio()
        }
    }

    func startBackgroundMusic() {
        guard AudioManager.shared.isEnabled else {
            audioQueue.async { [weak self] in self?.bgmPlayer?.stop() }
            return
        }
        audioQueue.async { [weak self] in
            guard let self = self, let player = self.bgmPlayer else { return }
            if !player.isPlaying {
                player.currentTime = 0
                player.play()
            }
        }
    }

    func pauseBackgroundMusic() {
        audioQueue.async { [weak self] in
            self?.bgmPlayer?.pause()
        }
    }

    func stopBackgroundMusic() {
        audioQueue.async { [weak self] in
            self?.bgmPlayer?.stop()
        }
    }

    func playNearMiss() {
        guard AudioManager.shared.isEnabled else { return }
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            if let player = self.nearMissPlayer {
                player.currentTime = 0
                player.play()
            } else {
                AudioManager.shared.play(.pop)
            }
        }
    }

    func playWarning() {
        guard AudioManager.shared.isEnabled else { return }
        audioQueue.async { [weak self] in
            guard let self = self, let player = self.warningPlayer else { return }
            player.currentTime = 0
            player.play()
        }
    }

    func playShieldBreak() {
        guard AudioManager.shared.isEnabled else { return }
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            if let player = self.shieldBreakPlayer {
                player.currentTime = 0
                player.play()
            } else {
                AudioManager.shared.play(.bounce)
            }
        }
    }

    private func buildSynthesizedAudio() {
        let bgmNotes: [(freq: Double, dur: Double)] = [
            (220.00, 0.22), (261.63, 0.22), (329.63, 0.22), (392.00, 0.22),
            (329.63, 0.22), (261.63, 0.22), (246.94, 0.22), (293.66, 0.22),
            (196.00, 0.22), (246.94, 0.22), (293.66, 0.22), (392.00, 0.22),
            (329.63, 0.22), (293.66, 0.22), (246.94, 0.22), (220.00, 0.22)
        ]
        if let wav = Self.makeSynthWAV(notes: bgmNotes, volume: 0.09) {
            bgmPlayer = try? AVAudioPlayer(data: wav)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.prepareToPlay()
        }

        let grazeNotes: [(freq: Double, dur: Double)] = [
            (587.33, 0.045), (880.00, 0.065)
        ]
        if let wav = Self.makeSynthWAV(notes: grazeNotes, volume: 0.22) {
            nearMissPlayer = try? AVAudioPlayer(data: wav)
            nearMissPlayer?.prepareToPlay()
        }

        let warnNotes: [(freq: Double, dur: Double)] = [
            (440.00, 0.07), (554.37, 0.09)
        ]
        if let wav = Self.makeSynthWAV(notes: warnNotes, volume: 0.20) {
            warningPlayer = try? AVAudioPlayer(data: wav)
            warningPlayer?.prepareToPlay()
        }

        let shieldNotes: [(freq: Double, dur: Double)] = [
            (523.25, 0.06), (392.00, 0.06), (659.25, 0.09)
        ]
        if let wav = Self.makeSynthWAV(notes: shieldNotes, volume: 0.25) {
            shieldBreakPlayer = try? AVAudioPlayer(data: wav)
            shieldBreakPlayer?.prepareToPlay()
        }
    }

    private static func makeSynthWAV(notes: [(freq: Double, dur: Double)], volume: Double) -> Data? {
        let sampleRate = 22050
        let totalDuration = notes.reduce(0.0) { $0 + $1.dur }
        let totalSamples = max(1, Int(totalDuration * Double(sampleRate)))

        var pcm = [Int16](repeating: 0, count: totalSamples)
        var sampleIndex = 0

        for note in notes {
            let count = Int(note.dur * Double(sampleRate))
            for i in 0..<count where sampleIndex < totalSamples {
                let t = Double(i) / Double(sampleRate)
                let env = min(1.0, Double(i) / 110.0) * max(0.0, 1.0 - Double(i) / Double(count))
                let phase = fmod(t * note.freq, 1.0)
                let triangle = 4.0 * abs(phase - 0.5) - 1.0
                let pulse = phase < 0.35 ? 0.4 : -0.4
                let raw = (triangle * 0.72 + pulse * 0.28) * env * volume
                pcm[sampleIndex] = Int16(max(-32767.0, min(32767.0, raw * 32767.0)))
                sampleIndex += 1
            }
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
}
