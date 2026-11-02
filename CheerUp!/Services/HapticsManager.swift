import CoreHaptics
import UIKit

// MARK: - Haptics Manager
// Wraps Core Haptics and UIImpactFeedbackGenerator for game feedback.

final class HapticsManager {
    static let shared = HapticsManager()

    private var engine: CHHapticEngine?
    private(set) var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "cheerup.haptics.enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "cheerup.haptics.enabled") }
    }
    private let supportsHaptics: Bool

    private init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

        // Default to enabled on first launch
        if UserDefaults.standard.object(forKey: "cheerup.haptics.enabled") == nil {
            UserDefaults.standard.set(true, forKey: "cheerup.haptics.enabled")
        }

        prepareEngine()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled { prepareEngine() }
    }

    // MARK: - Feedback Types

    /// Light tap — correct selection, bubble pop
    func lightTap() {
        guard isEnabled, supportsHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact — score milestone, combo
    func mediumImpact() {
        guard isEnabled, supportsHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact — collision, wrong tap, game over
    func heavyImpact() {
        guard isEnabled, supportsHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Flexible impact feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled, supportsHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Flexible notification feedback
    func notification(type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        guard isEnabled, supportsHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    /// Success — round complete, high score
    func success() {
        guard isEnabled, supportsHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning — time running low
    func warning() {
        guard isEnabled, supportsHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error — wrong selection, danger bubble
    func error() {
        guard isEnabled, supportsHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Soft selection — UI navigation
    func selection() {
        guard isEnabled, supportsHaptics else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Engine

    private func prepareEngine() {
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            // Haptics unavailable — fail silently
        }
    }
}
