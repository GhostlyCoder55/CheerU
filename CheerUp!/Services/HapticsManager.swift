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

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        if UserDefaults.standard.object(forKey: "cheerup.haptics.enabled") == nil {
            UserDefaults.standard.set(true, forKey: "cheerup.haptics.enabled")
        }
        prepare()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            prepare()
        }
    }

    func prepare() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.lightGenerator.prepare()
            self.mediumGenerator.prepare()
            self.heavyGenerator.prepare()
            self.selectionGenerator.prepare()
            self.notificationGenerator.prepare()
        }
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
        runOnMain { [weak self] in
            guard let self else { return }
            self.lightGenerator.impactOccurred()
            self.lightGenerator.prepare()
        }
    }

    /// Medium impact — score milestone, combo, wheel spin
    func mediumImpact() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.mediumGenerator.impactOccurred()
            self.mediumGenerator.prepare()
        }
    }

    /// Heavy impact — collision, wrong tap, chaos reveal
    func heavyImpact() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.heavyGenerator.impactOccurred()
            self.heavyGenerator.prepare()
        }
    }

    /// Flexible impact feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        runOnMain { [weak self] in
            guard let self else { return }
            switch style {
            case .light:
                self.lightGenerator.impactOccurred()
                self.lightGenerator.prepare()
            case .medium:
                self.mediumGenerator.impactOccurred()
                self.mediumGenerator.prepare()
            case .heavy, .rigid, .soft:
                self.heavyGenerator.impactOccurred()
                self.heavyGenerator.prepare()
            @unknown default:
                self.mediumGenerator.impactOccurred()
                self.mediumGenerator.prepare()
            }
        }
    }

    /// Success — round complete, high score, happy outcome
    func success() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.notificationGenerator.notificationOccurred(.success)
            self.notificationGenerator.prepare()
        }
    }

    /// Warning — time running low
    func warning() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.notificationGenerator.notificationOccurred(.warning)
            self.notificationGenerator.prepare()
        }
    }

    /// Error — wrong selection, timeout
    func error() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.notificationGenerator.notificationOccurred(.error)
            self.notificationGenerator.prepare()
        }
    }

    /// Soft selection — UI navigation, buttons
    func selection() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.selectionGenerator.selectionChanged()
            self.selectionGenerator.prepare()
        }
    }
}
