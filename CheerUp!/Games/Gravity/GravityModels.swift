import SwiftUI
import GameKit
import AVFoundation

// MARK: - Gravity Models & Types
// Data structures for CheerUp! Arcade — Gravity (Enchanted Torus Serpent).

struct GridCoord: Equatable, Hashable {
    var x: Int
    var y: Int
}

enum GravityDirection: Int, CaseIterable {
    case up = 0
    case right = 1
    case down = 2
    case left = 3

    var dx: Int {
        switch self {
        case .up, .down: return 0
        case .right:     return 1
        case .left:      return -1
        }
    }

    var dy: Int {
        switch self {
        case .up:            return 1
        case .down:          return -1
        case .left, .right:  return 0
        }
    }

    var opposite: GravityDirection {
        switch self {
        case .up:    return .down
        case .right: return .left
        case .down:  return .up
        case .left:  return .right
        }
    }

    func rotated(byQuarterTurnsCW turns: Int) -> GravityDirection {
        let normalized = ((rawValue + turns) % 4 + 4) % 4
        return GravityDirection(rawValue: normalized) ?? .up
    }
}

/// Represents the 4 cardinal gravity orientations of the enchanted torus world.
enum GravityOrientation: Int, CaseIterable {
    case south = 0 // 0°   (Standard: Down is South)
    case west  = 1 // 90°  (Rotated CW: Down is West)
    case north = 2 // 180° (Inverted: Down is North)
    case east  = 3 // 270° (Rotated CCW: Down is East)

    /// Scene zRotation in radians so the world smoothly rotates when gravity shifts
    var zRotationRadians: CGFloat {
        switch self {
        case .south: return 0
        case .west:  return .pi * 0.5
        case .north: return .pi
        case .east:  return -.pi * 0.5
        }
    }

    /// Degrees for SwiftUI compass indicator
    var compassDegrees: Double {
        switch self {
        case .south: return 0
        case .west:  return 90
        case .north: return 180
        case .east:  return 270
        }
    }

    var title: String {
        switch self {
        case .south:
            return LanguageManager.shared.tr("SOUTH GRAVITY", "GRAVITÉ SUD", "GRAVEDAD SUR")
        case .west:
            return LanguageManager.shared.tr("WEST GRAVITY", "GRAVITÉ OUEST", "GRAVEDAD OESTE")
        case .north:
            return LanguageManager.shared.tr("NORTH GRAVITY", "GRAVITÉ NORD", "GRAVEDAD NORTE")
        case .east:
            return LanguageManager.shared.tr("EAST GRAVITY", "GRAVITÉ EST", "GRAVEDAD ESTE")
        }
    }

    /// Maps a player's screen-space swipe direction into the world's grid direction
    /// so swiping UP/DOWN/LEFT/RIGHT on screen always steers the serpent in that screen direction!
    func screenToWorldDirection(_ screenDir: GravityDirection) -> GravityDirection {
        return screenDir.rotated(byQuarterTurnsCW: rawValue)
    }

    func shifted(byQuarterTurns turns: Int) -> GravityOrientation {
        let next = ((rawValue + turns) % 4 + 4) % 4
        return GravityOrientation(rawValue: next) ?? .south
    }
}

// MARK: - Elemental Motes

enum ElementalMoteType: String, CaseIterable, Identifiable {
    case fire  = "fire"
    case water = "water"
    case earth = "earth"
    case wind  = "wind"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .fire:
            return LanguageManager.shared.tr("FIRE MOTE", "ORBE DE FEU", "MOTA DE FUEGO")
        case .water:
            return LanguageManager.shared.tr("WATER MOTE", "ORBE D'EAU", "MOTA DE AGUA")
        case .earth:
            return LanguageManager.shared.tr("EARTH MOTE", "ORBE DE TERRE", "MOTA DE TIERRA")
        case .wind:
            return LanguageManager.shared.tr("WIND MOTE", "ORBE DE VENT", "MOTA DE VIENTO")
        }
    }

    var shortBadge: String {
        switch self {
        case .fire:  return LanguageManager.shared.tr("SPEED + 2X", "VITESSE + 2X", "VELOCIDAD + 2X")
        case .water: return LanguageManager.shared.tr("CALM FLOW", "RALENTI", "CALMA")
        case .earth: return LanguageManager.shared.tr("+3 GROWTH", "+3 TAILLE", "+3 TAMAÑO")
        case .wind:  return LanguageManager.shared.tr("PHASE BODY", "FANTÔME", "ETÉREO")
        }
    }

    var points: Int {
        switch self {
        case .fire:  return 3
        case .water: return 2
        case .earth: return 2
        case .wind:  return 2
        }
    }

    var growthSegments: Int {
        switch self {
        case .fire:  return 1
        case .water: return 1
        case .earth: return 3 // Earth adds bonus segments
        case .wind:  return 1
        }
    }

    var effectDuration: Double {
        switch self {
        case .fire:  return 5.5
        case .water: return 6.0
        case .earth: return 0.0 // Instant bonus growth
        case .wind:  return 7.5 // Phase through own body
        }
    }

    var color: Color {
        switch self {
        case .fire:  return Color(hex: 0xF59E0B) // Warm Amber Orange
        case .water: return Color(hex: 0x0284C7) // Ocean Azure Water Blue
        case .earth: return Color(hex: 0x10B981) // Emerald Forest Green
        case .wind:  return Color(hex: 0xBAE6FD) // Luminous Light Blue / White
        }
    }

    var colorHex: UInt {
        switch self {
        case .fire:  return 0xF59E0B
        case .water: return 0x0284C7 // Ocean Azure Water Blue
        case .earth: return 0x10B981
        case .wind:  return 0xBAE6FD // Light Blue / White
        }
    }
}

struct SpawnedMote: Identifiable, Equatable {
    let id: UUID = UUID()
    let type: ElementalMoteType
    var coord: GridCoord
}

struct ActiveElementalEffect: Identifiable, Equatable {
    var id: String { type.rawValue }
    let type: ElementalMoteType
    var remaining: Double
    let totalDuration: Double

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, remaining / totalDuration))
    }
}

enum GravityEvent: Equatable {
    case moved
    case moteCollected(ElementalMoteType, coord: GridCoord, pointsAdded: Int, newScore: Int)
    case gravityShifted(newOrientation: GravityOrientation, crossedEdge: GravityDirection)
    case windPhasedThroughSelf(coord: GridCoord)
    case gameOver(finalScore: Int, isNewBest: Bool)
}

// MARK: - Game Center Leaderboard Integration

final class GravityGameCenterManager {
    static let shared = GravityGameCenterManager()
    static let leaderboardID = "com.gc.CheerUp.gravity.endless"

    private init() {}

    func submitScore(_ score: Int) {
        GameCenterManager.shared.submitScore(score, for: .gravity)
    }
}

// MARK: - Enchanted Chiptune Background Music & Elemental Audio Synthesizer
// Synthesizes a gentle, mysterious enchanted forest chiptune loop in memory and
// respects AudioManager.shared.isEnabled.

final class GravityAudioController {
    static let shared = GravityAudioController()

    private var bgmPlayer: AVAudioPlayer?
    private var motePlayers: [ElementalMoteType: AVAudioPlayer] = [:]
    private var shiftPlayer: AVAudioPlayer?
    private let audioQueue = DispatchQueue(label: "com.gc.cheerup.gravity.audio", qos: .userInitiated)

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

    func playMoteSound(_ type: ElementalMoteType) {
        guard AudioManager.shared.isEnabled else { return }
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            if let player = self.motePlayers[type] {
                player.currentTime = 0
                player.play()
            }
        }
        AudioManager.shared.play(.pop)
    }

    func playGravityShiftSound() {
        guard AudioManager.shared.isEnabled else { return }
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            if let player = self.shiftPlayer {
                player.currentTime = 0
                player.play()
            } else {
                AudioManager.shared.play(.switchToggle)
            }
        }
    }

    private func buildSynthesizedAudio() {
        // 1. Enchanted Forest Arpeggio Loop (D Dorian mystical retro melody)
        let notes: [(freq: Double, dur: Double)] = [
            (293.66, 0.28), (349.23, 0.28), (440.00, 0.28), (523.25, 0.28),
            (493.88, 0.28), (440.00, 0.28), (349.23, 0.28), (329.63, 0.28),
            (293.66, 0.28), (392.00, 0.28), (440.00, 0.28), (587.33, 0.28),
            (523.25, 0.28), (440.00, 0.28), (392.00, 0.28), (349.23, 0.28)
        ]
        if let wavData = Self.makeChiptuneWAV(notes: notes, volume: 0.11) {
            bgmPlayer = try? AVAudioPlayer(data: wavData)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.prepareToPlay()
        }

        // 2. Distinct Elemental Mote Collection Chimes
        let fireNotes  = [(523.25, 0.06), (659.25, 0.06), (783.99, 0.09)]
        let waterNotes = [(587.33, 0.07), (493.88, 0.07), (392.00, 0.10)]
        let earthNotes = [(329.63, 0.07), (440.00, 0.07), (523.25, 0.11)]
        let windNotes  = [(440.00, 0.05), (554.37, 0.05), (659.25, 0.05), (880.00, 0.09)]

        for (type, seq) in [
            (ElementalMoteType.fire, fireNotes),
            (.water, waterNotes),
            (.earth, earthNotes),
            (.wind, windNotes)
        ] {
            if let data = Self.makeChiptuneWAV(notes: seq, volume: 0.24) {
                let p = try? AVAudioPlayer(data: data)
                p?.prepareToPlay()
                motePlayers[type] = p
            }
        }

        // 3. Mystical Gravity Shift Whoosh/Chime
        let shiftNotes = [(349.23, 0.05), (440.00, 0.05), (523.25, 0.08)]
        if let data = Self.makeChiptuneWAV(notes: shiftNotes, volume: 0.20) {
            shiftPlayer = try? AVAudioPlayer(data: data)
            shiftPlayer?.prepareToPlay()
        }
    }

    private static func makeChiptuneWAV(notes: [(freq: Double, dur: Double)], volume: Double) -> Data? {
        let sampleRate = 22050
        let totalDuration = notes.reduce(0.0) { $0 + $1.dur }
        let totalSamples = max(1, Int(totalDuration * Double(sampleRate)))

        var pcm = [Int16](repeating: 0, count: totalSamples)
        var sampleIndex = 0

        for note in notes {
            let count = Int(note.dur * Double(sampleRate))
            for i in 0..<count where sampleIndex < totalSamples {
                let t = Double(i) / Double(sampleRate)
                let env = min(1.0, Double(i) / 140.0) * max(0.0, 1.0 - Double(i) / Double(count))
                // Soft triangle + subtle square overtone for warm 8-bit forest feel
                let phase = fmod(t * note.freq, 1.0)
                let triangle = 4.0 * abs(phase - 0.5) - 1.0
                let square = phase < 0.5 ? 0.35 : -0.35
                let raw = (triangle * 0.75 + square * 0.25) * env * volume
                pcm[sampleIndex] = Int16(max(-32767.0, min(32767.0, raw * 32767.0)))
                sampleIndex += 1
            }
        }

        let dataSize = pcm.count * 2
        let fileSize = 36 + dataSize
        var header = Data()

        header.append(Data("RIFF".utf8))
        header.append(uint32LE(UInt32(fileSize)))
        header.append(Data("WAVE".utf8))
        header.append(Data("fmt ".utf8))
        header.append(uint32LE(16))
        header.append(uint16LE(1)) // PCM
        header.append(uint16LE(1)) // Mono
        header.append(uint32LE(UInt32(sampleRate)))
        header.append(uint32LE(UInt32(sampleRate * 2)))
        header.append(uint16LE(2))
        header.append(uint16LE(16))
        header.append(Data("data".utf8))
        header.append(uint32LE(UInt32(dataSize)))

        pcm.withUnsafeBufferPointer { ptr in
            header.append(UnsafeBufferPointer(
                start: UnsafeRawPointer(ptr.baseAddress!)?.assumingMemoryBound(to: UInt8.self),
                count: dataSize
            ))
        }
        return header
    }

    private static func uint32LE(_ val: UInt32) -> Data {
        var v = val.littleEndian
        return Data(bytes: &v, count: 4)
    }

    private static func uint16LE(_ val: UInt16) -> Data {
        var v = val.littleEndian
        return Data(bytes: &v, count: 2)
    }
}
