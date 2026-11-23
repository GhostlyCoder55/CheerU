import UIKit

// MARK: - Haptics Manager
// High-performance tactile feedback using UIKit feedback generators.
// Safe to invoke from any synchronous or nonisolated context.

final class HapticsManager: @unchecked Sendable {
    static let shared = HapticsManager()

    private static let enabledKey = "cheerup.haptics.enabled"
    private var _isEnabled: Bool
    private(set) var isEnabled: Bool {
        get { _isEnabled }
        set {
            _isEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
        }
    }

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private var lastPrepareTime: CFTimeInterval = 0

    private init() {
        if UserDefaults.standard.object(forKey: Self.enabledKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.enabledKey)
            _isEnabled = true
        } else {
            _isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
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
            self.lastPrepareTime = CACurrentMediaTime()
            self.lightGenerator.prepare()
            self.mediumGenerator.prepare()
            self.heavyGenerator.prepare()
            self.selectionGenerator.prepare()
            self.notificationGenerator.prepare()
        }
    }

    private func prepareIfNeeded(_ generator: UIFeedbackGenerator) {
        let now = CACurrentMediaTime()
        if now - lastPrepareTime >= 0.45 {
            lastPrepareTime = now
            generator.prepare()
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
            self.prepareIfNeeded(self.lightGenerator)
        }
    }

    /// Medium impact — score milestone, combo, wheel spin
    func mediumImpact() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.mediumGenerator.impactOccurred()
            self.prepareIfNeeded(self.mediumGenerator)
        }
    }

    /// Heavy impact — collision, wrong tap, chaos reveal
    func heavyImpact() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.heavyGenerator.impactOccurred()
            self.prepareIfNeeded(self.heavyGenerator)
        }
    }

    /// Flexible impact feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        runOnMain { [weak self] in
            guard let self else { return }
            switch style {
            case .light:
                self.lightGenerator.impactOccurred()
                self.prepareIfNeeded(self.lightGenerator)
            case .medium:
                self.mediumGenerator.impactOccurred()
                self.prepareIfNeeded(self.mediumGenerator)
            case .heavy, .rigid, .soft:
                self.heavyGenerator.impactOccurred()
                self.prepareIfNeeded(self.heavyGenerator)
            @unknown default:
                self.mediumGenerator.impactOccurred()
                self.prepareIfNeeded(self.mediumGenerator)
            }
        }
    }

    /// Success — round complete, high score, happy outcome
    func success() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.notificationGenerator.notificationOccurred(.success)
            self.prepareIfNeeded(self.notificationGenerator)
        }
    }

    /// Warning — time running low
    func warning() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.notificationGenerator.notificationOccurred(.warning)
            self.prepareIfNeeded(self.notificationGenerator)
        }
    }

    /// Error — wrong selection, timeout
    func error() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.notificationGenerator.notificationOccurred(.error)
            self.prepareIfNeeded(self.notificationGenerator)
        }
    }

    /// Soft selection — UI navigation, buttons
    func selection() {
        runOnMain { [weak self] in
            guard let self else { return }
            self.selectionGenerator.selectionChanged()
            self.prepareIfNeeded(self.selectionGenerator)
        }
    }
}
