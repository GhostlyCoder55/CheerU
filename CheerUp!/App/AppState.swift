import SwiftUI

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
