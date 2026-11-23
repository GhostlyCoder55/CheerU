import SwiftUI
import UIKit

// MARK: - Mobile Display Config
// Adapts SpriteKit render cadence to the device's native refresh rate (60Hz standard,
// up to 120Hz on ProMotion iPhones — mirrors Android Display.Mode.refreshRate).

enum MobileDisplayConfig {
    static var preferredGameFPS: Int {
        let maxFPS = UIScreen.main.maximumFramesPerSecond
        return min(120, max(60, maxFPS))
    }
}

// MARK: - App State
// Observable object managing navigation and global state.

@Observable
final class AppState {
    var selectedGame: GameIdentifier?
    var showingIntro: Bool = false
    var isPlayingGame: Bool = false

    func selectGame(_ game: GameIdentifier) {
        selectedGame = game
        showingIntro = true
    }

    func startGame() {
        showingIntro = false
        isPlayingGame = true
    }

    func exitToArcade() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isPlayingGame = false
            showingIntro = false
            selectedGame = nil
        }
    }

    func showIntro() {
        isPlayingGame = false
        showingIntro = true
    }
}
