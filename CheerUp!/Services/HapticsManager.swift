import UIKit

// MARK: - Haptics Manager
// High-performance tactile feedback using pre-warmed UIKit feedback generators.

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()

    private(set) var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "cheerup.haptics.enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "cheerup.haptics.enabled") }
    }

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        if UserDefaults.standard.object(forKey: "cheerup.haptics.enabled") == nil {
            UserDefaults.standard.set(true, forKey: "cheerup.haptics.enabled")
        }
        prepareAll()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled { prepareAll() }
    }

    private func prepareAll() {
        guard isEnabled else { return }
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Feedback Types

    /// Light tap — correct selection, bubble pop
    func lightTap() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred()
    }

    /// Medium impact — score milestone, combo
    func mediumImpact() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
    }

    /// Heavy impact — collision, wrong tap, game over
    func heavyImpact() {
        guard isEnabled else { return }
        heavyGenerator.impactOccurred()
    }

    /// Flexible impact feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }
        switch style {
        case .light:  lightGenerator.impactOccurred()
        case .medium: mediumGenerator.impactOccurred()
        case .heavy:  heavyGenerator.impactOccurred()
        default:
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }

    /// Success — round complete, high score
    func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning — time running low
    func warning() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error — wrong selection, timeout
    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }

    /// Soft selection — UI navigation, buttons
    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }
}
