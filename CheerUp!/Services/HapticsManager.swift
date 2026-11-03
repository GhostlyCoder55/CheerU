import UIKit

// MARK: - Haptics Manager
// High-performance tactile feedback using UIKit feedback generators.
// Safe to invoke from any synchronous or nonisolated context.

final class HapticsManager: @unchecked Sendable {
    static let shared = HapticsManager()

    private(set) var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "cheerup.haptics.enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "cheerup.haptics.enabled") }
    }

    private init() {
        if UserDefaults.standard.object(forKey: "cheerup.haptics.enabled") == nil {
            UserDefaults.standard.set(true, forKey: "cheerup.haptics.enabled")
        }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    private func runOnMain(_ action: @escaping () -> Void) {
        guard isEnabled else { return }
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }

    // MARK: - Feedback Types

    /// Light tap — correct selection, bubble pop, needle tick
    func lightTap() {
        runOnMain {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    /// Medium impact — score milestone, combo, wheel spin
    func mediumImpact() {
        runOnMain {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }

    /// Heavy impact — collision, wrong tap, chaos reveal
    func heavyImpact() {
        runOnMain {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }

    /// Flexible impact feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        runOnMain {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }

    /// Success — round complete, high score, happy outcome
    func success() {
        runOnMain {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    /// Warning — time running low
    func warning() {
        runOnMain {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }

    /// Error — wrong selection, timeout
    func error() {
        runOnMain {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    /// Soft selection — UI navigation, buttons
    func selection() {
        runOnMain {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}
