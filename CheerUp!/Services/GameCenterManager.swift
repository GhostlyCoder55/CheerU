import Foundation
@preconcurrency import GameKit
import UIKit

// MARK: - Game Center Manager
// Unified leaderboard authentication and score submission for all CheerUp! mini-games.

final class GameCenterManager: @unchecked Sendable {
    static let shared = GameCenterManager()

    enum SubmissionError: Error, Equatable {
        case invalidLeaderboard
        case nonPositiveScore
        case notAuthenticated
    }

    typealias AuthenticationProvider = @Sendable () -> Bool
    typealias ScoreSubmitter = @Sendable (_ score: Int, _ context: Int, _ leaderboardID: String, _ completion: @escaping @Sendable (Error?) -> Void) -> Void

    private let stateLock = NSLock()
    private var _isAuthenticated: Bool = false
    private var _lastAuthenticationError: Error?
    private var _lastSubmissionError: Error?
    private var _hasConfiguredAuthHandler: Bool = false
    private var _isPlayerAuthenticatedProvider: AuthenticationProvider
    private var _scoreSubmitter: ScoreSubmitter

    var isAuthenticated: Bool {
        stateLock.withLock { _isAuthenticated }
    }

    var lastAuthenticationError: Error? {
        stateLock.withLock { _lastAuthenticationError }
    }

    var lastSubmissionError: Error? {
        stateLock.withLock { _lastSubmissionError }
    }

    private init() {
        self._isPlayerAuthenticatedProvider = { GKLocalPlayer.local.isAuthenticated }
        self._scoreSubmitter = Self.defaultScoreSubmitter
    }

    /// Designated internal initializer for isolated unit tests.
    init(
        isPlayerAuthenticated: @escaping AuthenticationProvider,
        scoreSubmitter: @escaping ScoreSubmitter
    ) {
        self._isPlayerAuthenticatedProvider = isPlayerAuthenticated
        self._scoreSubmitter = scoreSubmitter
        self._isAuthenticated = isPlayerAuthenticated()
    }

    // MARK: - Leaderboard Identifiers
    static func leaderboardID(for game: GameIdentifier) -> String? {
        switch game {
        case .tap:      return "com.gc.cheerup.tap.highscore"
        case .pingPong: return "com.gc.cheerup.pingpong.highscore"
        case .gravity:  return "com.gc.cheerup.gravity.highscore"
        case .rush:     return "com.gc.cheerup.rush.highscore"
        case .chess:    return "com.gc.cheerup.chess.wins"
        case .wheels:   return nil
        }
    }

    func leaderboardID(for game: GameIdentifier) -> String? {
        Self.leaderboardID(for: game)
    }

    // MARK: - Player Authentication
    func authenticateLocalPlayer() {
        let shouldConfigure = stateLock.withLock { () -> Bool in
            guard !_hasConfiguredAuthHandler else { return false }
            _hasConfiguredAuthHandler = true
            return true
        }
        guard shouldConfigure else { return }

        let assignHandler: @Sendable () -> Void = { [weak self] in
            GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    let authenticated = GKLocalPlayer.local.isAuthenticated
                    self.stateLock.withLock {
                        self._isAuthenticated = authenticated
                        self._lastAuthenticationError = error
                    }

                    if let vc = viewController,
                       !authenticated,
                       !vc.isBeingPresented,
                       let top = Self.topViewController(),
                       top !== vc,
                       top.presentedViewController == nil {
                        top.present(vc, animated: true)
                    }
                }
            }
        }

        if Thread.isMainThread {
            assignHandler()
        } else {
            DispatchQueue.main.async(execute: assignHandler)
        }
    }

    // MARK: - Unified Score Submission
    func submitScore(
        _ score: Int,
        for game: GameIdentifier,
        completion: (@Sendable (Result<Void, Error>) -> Void)? = nil
    ) {
        guard let id = leaderboardID(for: game) else {
            completion?(.failure(SubmissionError.invalidLeaderboard))
            return
        }
        guard score > 0 else {
            completion?(.failure(SubmissionError.nonPositiveScore))
            return
        }
        let isAuthProvider = stateLock.withLock { _isPlayerAuthenticatedProvider }
        guard isAuthProvider() else {
            stateLock.withLock { _isAuthenticated = false }
            completion?(.failure(SubmissionError.notAuthenticated))
            return
        }

        let submitter = stateLock.withLock { _scoreSubmitter }
        submitter(score, 0, id) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.stateLock.withLock {
                    self._lastSubmissionError = error
                }
                if let error {
                    completion?(.failure(error))
                } else {
                    completion?(.success(()))
                }
            }
        }
    }

    private static let defaultScoreSubmitter: ScoreSubmitter = { score, context, leaderboardID, completion in
        DispatchQueue.global(qos: .utility).async {
            GKLeaderboard.submitScore(
                score,
                context: context,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID],
                completionHandler: completion
            )
        }
    }

    // MARK: - Testing Support
    func configureForTesting(
        isPlayerAuthenticated: @escaping AuthenticationProvider,
        scoreSubmitter: @escaping ScoreSubmitter
    ) {
        stateLock.withLock {
            _isPlayerAuthenticatedProvider = isPlayerAuthenticated
            _scoreSubmitter = scoreSubmitter
            _isAuthenticated = isPlayerAuthenticated()
            _lastSubmissionError = nil
        }
    }

    func resetTestingConfiguration() {
        stateLock.withLock {
            _isPlayerAuthenticatedProvider = { GKLocalPlayer.local.isAuthenticated }
            _scoreSubmitter = Self.defaultScoreSubmitter
            _isAuthenticated = GKLocalPlayer.local.isAuthenticated
            _lastSubmissionError = nil
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let activeScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

        guard let root = activeScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
