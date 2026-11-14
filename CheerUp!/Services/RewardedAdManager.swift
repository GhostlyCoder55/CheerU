import Foundation
import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - AdMob Configuration

enum AdMobConfig {
    // MARK: - Arcade Games (Tap, Rush, Gravity, Ping Pong) — Rewarded Video Ad
    /// Production Rewarded Ad Unit ID for Arcade game over continuation.
    static let arcadeRewardedAdUnitID = "ca-app-pub-8075634631393674/9803471775"
    /// Official Google Test Rewarded Ad Unit ID.
    static let testArcadeRewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    // MARK: - Wheels Section (Every 5 Spins) — Rewarded Interstitial Ad
    /// Production Rewarded Interstitial Ad Unit ID for Wheels.
    static let wheelsAdUnitID = "ca-app-pub-8075634631393674/3191805276"
    /// Official Google Test Rewarded Interstitial Ad Unit ID.
    static let testWheelsAdUnitID = "ca-app-pub-3940256099942544/6978759866"

    // Backward compatibility aliases
    static var rewardedAdUnitID: String { arcadeRewardedAdUnitID }
    static var productionRewardedAdUnitID: String { arcadeRewardedAdUnitID }
    static var testRewardedAdUnitID: String { testArcadeRewardedAdUnitID }
}

// MARK: - Rewarded Ad State

enum RewardedAdState: Equatable {
    case idle
    case loading
    case ready
    case presenting
    case failed(String)

    var isBusy: Bool {
        self == .loading || self == .presenting
    }
}

// MARK: - Rewarded Ad Manager
// Manages Rewarded Ads for Arcade games and Rewarded Interstitials for Wheels using modern Swift async/await APIs.

@Observable
@MainActor
final class RewardedAdManager: NSObject {
    static let shared = RewardedAdManager()

    private(set) var arcadeState: RewardedAdState = .idle
    private(set) var wheelsState: RewardedAdState = .idle
    private(set) var isPresentingAd: Bool = false

    /// Backward compatibility alias for arcadeState
    var state: RewardedAdState {
        get { arcadeState }
        set { arcadeState = newValue }
    }

    private var hasEarnedRewardForCurrentAd: Bool = false
    private var isSDKStarted: Bool = false

    private var onRewardEarnedHandler: (() -> Void)?
    private var onDismissedWithoutRewardHandler: (() -> Void)?

    #if canImport(GoogleMobileAds)
    private var arcadeRewardedAd: RewardedAd?
    private var wheelsRewardedInterstitialAd: RewardedInterstitialAd?
    private var wheelsFallbackRewardedAd: RewardedAd?
    #endif

    private override init() {
        super.init()
    }

    // MARK: - SDK Initialization

    func startSDKIfNeeded() {
        guard !isSDKStarted else { return }
        isSDKStarted = true
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start { _ in }
        #endif
    }

    // MARK: - Preload (Never auto-presents)

    func preloadAllIfNeeded() {
        preloadArcadeAdIfNeeded()
        preloadWheelsAdIfNeeded()
    }

    /// Preloads arcade rewarded ad (Tap, Rush, Gravity, Ping Pong)
    func preloadArcadeAdIfNeeded() {
        startSDKIfNeeded()

        guard !isPresentingAd else { return }
        guard arcadeState != .loading && arcadeState != .ready else { return }

        #if canImport(GoogleMobileAds)
        arcadeState = .loading
        Task { @MainActor in
            do {
                let ad = try await RewardedAd.load(with: AdMobConfig.arcadeRewardedAdUnitID, request: Request())
                self.arcadeRewardedAd = ad
                self.arcadeRewardedAd?.fullScreenContentDelegate = self
                self.arcadeState = .ready
            } catch {
                self.arcadeRewardedAd = nil
                self.arcadeState = .failed(error.localizedDescription)
            }
        }
        #else
        arcadeState = .failed(
            LanguageManager.shared.tr(
                "AdMob SDK not linked yet.",
                "SDK AdMob non lié.",
                "SDK de AdMob no vinculado."
            )
        )
        #endif
    }

    /// Preloads Wheels rewarded interstitial ad (after 5 spins)
    func preloadWheelsAdIfNeeded() {
        startSDKIfNeeded()

        guard !isPresentingAd else { return }
        guard wheelsState != .loading && wheelsState != .ready else { return }

        #if canImport(GoogleMobileAds)
        wheelsState = .loading
        Task { @MainActor in
            do {
                let ad = try await RewardedInterstitialAd.load(with: AdMobConfig.wheelsAdUnitID, request: Request())
                self.wheelsRewardedInterstitialAd = ad
                self.wheelsRewardedInterstitialAd?.fullScreenContentDelegate = self
                self.wheelsState = .ready
            } catch {
                // Fallback to standard RewardedAd if unit was created with Rewarded format
                do {
                    let fallbackAd = try await RewardedAd.load(with: AdMobConfig.wheelsAdUnitID, request: Request())
                    self.wheelsFallbackRewardedAd = fallbackAd
                    self.wheelsFallbackRewardedAd?.fullScreenContentDelegate = self
                    self.wheelsState = .ready
                } catch let fallbackError {
                    self.wheelsRewardedInterstitialAd = nil
                    self.wheelsFallbackRewardedAd = nil
                    self.wheelsState = .failed(fallbackError.localizedDescription)
                }
            }
        }
        #else
        wheelsState = .failed(
            LanguageManager.shared.tr(
                "AdMob SDK not linked yet.",
                "SDK AdMob non lié.",
                "SDK de AdMob no vinculado."
            )
        )
        #endif
    }

    /// Backward compatibility alias for preloadArcadeAdIfNeeded
    func preloadIfNeeded() {
        preloadArcadeAdIfNeeded()
    }

    // MARK: - Arcade Games Ad Presentation (Tap, Rush, Gravity, Ping Pong)

    func presentRewardedAd(
        onRewardEarned: @escaping () -> Void,
        onDismissedWithoutReward: (() -> Void)? = nil
    ) {
        guard !isPresentingAd, arcadeState != .presenting else { return }

        startSDKIfNeeded()

        #if canImport(GoogleMobileAds)
        if let ad = arcadeRewardedAd {
            presentLoadedArcadeAd(
                ad,
                onRewardEarned: onRewardEarned,
                onDismissedWithoutReward: onDismissedWithoutReward
            )
            return
        }

        guard arcadeState != .loading else { return }
        arcadeState = .loading
        Task { @MainActor in
            do {
                let ad = try await RewardedAd.load(with: AdMobConfig.arcadeRewardedAdUnitID, request: Request())
                self.arcadeRewardedAd = ad
                self.presentLoadedArcadeAd(
                    ad,
                    onRewardEarned: onRewardEarned,
                    onDismissedWithoutReward: onDismissedWithoutReward
                )
            } catch {
                self.arcadeRewardedAd = nil
                self.arcadeState = .failed(error.localizedDescription)
                onDismissedWithoutReward?()
            }
        }
        #else
        arcadeState = .failed(
            LanguageManager.shared.tr(
                "Add GoogleMobileAds Swift Package in Xcode to enable rewarded videos.",
                "Ajoutez le package GoogleMobileAds dans Xcode pour activer les vidéos.",
                "Agrega el paquete GoogleMobileAds en Xcode para activar los videos."
            )
        )
        onDismissedWithoutReward?()
        #endif
    }

    // MARK: - Wheels Section Ad Presentation (Every 5 Spins)

    func presentWheelsAd(
        onRewardEarned: @escaping () -> Void,
        onDismissedWithoutReward: (() -> Void)? = nil
    ) {
        guard !isPresentingAd, wheelsState != .presenting else { return }

        startSDKIfNeeded()

        #if canImport(GoogleMobileAds)
        if let ad = wheelsRewardedInterstitialAd {
            presentLoadedWheelsInterstitialAd(
                ad,
                onRewardEarned: onRewardEarned,
                onDismissedWithoutReward: onDismissedWithoutReward
            )
            return
        }

        if let ad = wheelsFallbackRewardedAd {
            presentLoadedWheelsRewardedAd(
                ad,
                onRewardEarned: onRewardEarned,
                onDismissedWithoutReward: onDismissedWithoutReward
            )
            return
        }

        guard wheelsState != .loading else { return }
        wheelsState = .loading
        Task { @MainActor in
            do {
                let ad = try await RewardedInterstitialAd.load(with: AdMobConfig.wheelsAdUnitID, request: Request())
                self.wheelsRewardedInterstitialAd = ad
                self.presentLoadedWheelsInterstitialAd(
                    ad,
                    onRewardEarned: onRewardEarned,
                    onDismissedWithoutReward: onDismissedWithoutReward
                )
            } catch {
                // Fallback to standard RewardedAd
                do {
                    let fallbackAd = try await RewardedAd.load(with: AdMobConfig.wheelsAdUnitID, request: Request())
                    self.wheelsFallbackRewardedAd = fallbackAd
                    self.presentLoadedWheelsRewardedAd(
                        fallbackAd,
                        onRewardEarned: onRewardEarned,
                        onDismissedWithoutReward: onDismissedWithoutReward
                    )
                } catch let fallbackError {
                    self.wheelsState = .failed(fallbackError.localizedDescription)
                    onDismissedWithoutReward?()
                }
            }
        }
        #else
        wheelsState = .failed(
            LanguageManager.shared.tr(
                "Add GoogleMobileAds Swift Package in Xcode to enable video ads.",
                "Ajoutez le package GoogleMobileAds dans Xcode pour activer les vidéos.",
                "Agrega el paquete GoogleMobileAds en Xcode para activer los videos."
            )
        )
        onDismissedWithoutReward?()
        #endif
    }

    #if canImport(GoogleMobileAds)
    private func presentLoadedArcadeAd(
        _ ad: RewardedAd,
        onRewardEarned: @escaping () -> Void,
        onDismissedWithoutReward: (() -> Void)?
    ) {
        guard let rootViewController = Self.topViewController() else {
            arcadeState = .failed("Unable to find active window.")
            onDismissedWithoutReward?()
            return
        }

        isPresentingAd = true
        hasEarnedRewardForCurrentAd = false
        onRewardEarnedHandler = onRewardEarned
        onDismissedWithoutRewardHandler = onDismissedWithoutReward
        arcadeState = .presenting

        ad.fullScreenContentDelegate = self
        ad.present(from: rootViewController) { [weak self] in
            Self.runOnMain {
                self?.markRewardEarned()
            }
        }
    }

    private func presentLoadedWheelsInterstitialAd(
        _ ad: RewardedInterstitialAd,
        onRewardEarned: @escaping () -> Void,
        onDismissedWithoutReward: (() -> Void)?
    ) {
        guard let rootViewController = Self.topViewController() else {
            wheelsState = .failed("Unable to find active window.")
            onDismissedWithoutReward?()
            return
        }

        isPresentingAd = true
        hasEarnedRewardForCurrentAd = false
        onRewardEarnedHandler = onRewardEarned
        onDismissedWithoutRewardHandler = onDismissedWithoutReward
        wheelsState = .presenting

        ad.fullScreenContentDelegate = self
        ad.present(from: rootViewController) { [weak self] in
            Self.runOnMain {
                self?.markRewardEarned()
            }
        }
    }

    private func presentLoadedWheelsRewardedAd(
        _ ad: RewardedAd,
        onRewardEarned: @escaping () -> Void,
        onDismissedWithoutReward: (() -> Void)?
    ) {
        guard let rootViewController = Self.topViewController() else {
            wheelsState = .failed("Unable to find active window.")
            onDismissedWithoutReward?()
            return
        }

        isPresentingAd = true
        hasEarnedRewardForCurrentAd = false
        onRewardEarnedHandler = onRewardEarned
        onDismissedWithoutRewardHandler = onDismissedWithoutReward
        wheelsState = .presenting

        ad.fullScreenContentDelegate = self
        ad.present(from: rootViewController) { [weak self] in
            Self.runOnMain {
                self?.markRewardEarned()
            }
        }
    }
    #endif

    private nonisolated static func runOnMain(_ block: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                block()
            }
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    block()
                }
            }
        }
    }

    // MARK: - Reward & Lifecycle State Helpers (Internal for Unit Testing)

    @discardableResult
    func markRewardEarned() -> Bool {
        guard isPresentingAd, !hasEarnedRewardForCurrentAd else {
            return false
        }
        hasEarnedRewardForCurrentAd = true
        return true
    }

    func completePresentation(didFailToPresent: Bool = false, errorMessage: String? = nil) {
        let earned = !didFailToPresent && hasEarnedRewardForCurrentAd
        let rewardHandler = onRewardEarnedHandler
        let dismissHandler = onDismissedWithoutRewardHandler

        isPresentingAd = false
        hasEarnedRewardForCurrentAd = false
        onRewardEarnedHandler = nil
        onDismissedWithoutRewardHandler = nil

        #if canImport(GoogleMobileAds)
        arcadeRewardedAd = nil
        wheelsRewardedInterstitialAd = nil
        wheelsFallbackRewardedAd = nil
        #endif

        if didFailToPresent {
            let msg = errorMessage ?? "Ad failed to present."
            arcadeState = .failed(msg)
            wheelsState = .failed(msg)
            dismissHandler?()
        } else {
            arcadeState = .idle
            wheelsState = .idle
            if earned {
                rewardHandler?()
            } else {
                dismissHandler?()
            }
        }
    }

    func beginTestPresentation(
        onRewardEarned: @escaping () -> Void,
        onDismissedWithoutReward: (() -> Void)? = nil
    ) -> Bool {
        guard !isPresentingAd else { return false }
        isPresentingAd = true
        hasEarnedRewardForCurrentAd = false
        arcadeState = .presenting
        wheelsState = .presenting
        onRewardEarnedHandler = onRewardEarned
        onDismissedWithoutRewardHandler = onDismissedWithoutReward
        return true
    }

    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? windowScene.windows.first?.rootViewController
        else {
            return nil
        }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

#if canImport(GoogleMobileAds)
extension RewardedAdManager: FullScreenContentDelegate {
    nonisolated func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Self.runOnMain { [weak self] in
            self?.completePresentation(
                didFailToPresent: true,
                errorMessage: error.localizedDescription
            )
        }
    }

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Self.runOnMain { [weak self] in
            self?.completePresentation(didFailToPresent: false)
        }
    }
}
#endif
