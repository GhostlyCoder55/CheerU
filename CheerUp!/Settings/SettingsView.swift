import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @State private var soundEnabled: Bool = AudioManager.shared.isEnabled
    @State private var hapticsEnabled: Bool = HapticsManager.shared.isEnabled

    var body: some View {
        NavigationStack {
            ZStack {
                CheerUpColors.deepNavy.ignoresSafeArea()

                List {
                    Section {
                        Toggle(isOn: $soundEnabled) {
                            Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                        }
                        .onChange(of: soundEnabled) { _, newValue in
                            AudioManager.shared.setEnabled(newValue)
                        }

                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptic Feedback", systemImage: "hand.tap.fill")
                        }
                        .onChange(of: hapticsEnabled) { _, newValue in
                            HapticsManager.shared.setEnabled(newValue)
                        }
                    } header: {
                        Text("PREFERENCES")
                    }

                    Section {
                        Button(role: .destructive) {
                            resetScores()
                        } label: {
                            Label("Reset All High Scores", systemImage: "trash")
                        }
                    } header: {
                        Text("DATA")
                    }

                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("2.0")
                                .foregroundStyle(CheerUpColors.mutedSilver)
                        }
                    } header: {
                        Text("ABOUT")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(CheerUpColors.lightGrey)
    }

    private func resetScores() {
        for game in GameIdentifier.allCases {
            UserDefaults.standard.removeObject(forKey: "cheerup.highscore.\(game.rawValue)")
        }
        HapticsManager.shared.success()
    }
}
