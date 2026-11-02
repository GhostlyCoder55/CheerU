import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @State private var soundEnabled: Bool = AudioManager.shared.isEnabled
    @State private var hapticsEnabled: Bool = HapticsManager.shared.isEnabled
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                CheerUpColors.deepNavy.ignoresSafeArea()

                List {
                    Section {
                        Toggle(isOn: $soundEnabled) {
                            Label(languageManager.tr("Sound Effects", "Sons"), systemImage: "speaker.wave.2.fill")
                        }
                        .onChange(of: soundEnabled) { _, newValue in
                            AudioManager.shared.setEnabled(newValue)
                        }

                        Toggle(isOn: $hapticsEnabled) {
                            Label(languageManager.tr("Haptic Feedback", "Vibrations"), systemImage: "hand.tap.fill")
                        }
                        .onChange(of: hapticsEnabled) { _, newValue in
                            HapticsManager.shared.setEnabled(newValue)
                        }
                    } header: {
                        Text(languageManager.tr("PREFERENCES", "PRÉFÉRENCES"))
                    }

                    Section {
                        Picker(selection: $languageManager.currentLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        } label: {
                            Label(languageManager.tr("Language", "Langue"), systemImage: "globe")
                        }
                        .pickerStyle(.menu)
                    } header: {
                        Text(languageManager.tr("LANGUAGE", "LANGUE"))
                    }

                    Section {
                        HStack {
                            Text(languageManager.tr("Version", "Version"))
                            Spacer()
                            Text("2.0")
                                .foregroundStyle(CheerUpColors.mutedSilver)
                        }
                    } header: {
                        Text(languageManager.tr("ABOUT", "À PROPOS"))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(languageManager.tr("Settings", "Réglages"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(CheerUpColors.lightGrey)
    }
}
