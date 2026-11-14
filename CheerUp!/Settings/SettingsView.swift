import SwiftUI
import UIKit

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @State private var soundEnabled: Bool = AudioManager.shared.isEnabled
    @State private var hapticsEnabled: Bool = HapticsManager.shared.isEnabled
    @State private var notificationsEnabled: Bool = NotificationManager.shared.isEnabled
    @State private var showNotificationDeniedAlert = false
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                CheerUpColors.deepNavy.ignoresSafeArea()

                List {
                    Section {
                        Toggle(isOn: $soundEnabled) {
                            Label(languageManager.tr("Sound Effects", "Sons", "Sonidos"), systemImage: "speaker.wave.2.fill")
                        }
                        .onChange(of: soundEnabled) { _, newValue in
                            AudioManager.shared.setEnabled(newValue)
                        }

                        Toggle(isOn: $hapticsEnabled) {
                            Label(languageManager.tr("Haptic Feedback", "Vibrations", "Vibración"), systemImage: "hand.tap.fill")
                        }
                        .onChange(of: hapticsEnabled) { _, newValue in
                            HapticsManager.shared.setEnabled(newValue)
                        }

                        Toggle(isOn: $notificationsEnabled) {
                            Label(languageManager.tr("Play Reminders", "Rappels de jeu", "Recordatorios"), systemImage: "bell.badge.fill")
                        }
                        .onChange(of: notificationsEnabled) { _, newValue in
                            Task {
                                let success = await NotificationManager.shared.setEnabled(newValue)
                                if !success && newValue {
                                    notificationsEnabled = false
                                    showNotificationDeniedAlert = true
                                }
                            }
                        }
                    } header: {
                        Text(languageManager.tr("PREFERENCES", "PRÉFÉRENCES", "PREFERENCIAS"))
                    }

                    Section {
                        Picker(selection: $languageManager.currentLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        } label: {
                            Label(languageManager.tr("Language", "Langue", "Idioma"), systemImage: "globe")
                        }
                        .pickerStyle(.menu)
                        .onChange(of: languageManager.currentLanguage) { _, _ in
                            Task {
                                await NotificationManager.shared.refreshScheduleIfNeeded()
                            }
                        }
                    } header: {
                        Text(languageManager.tr("LANGUAGE", "LANGUE", "IDIOMA"))
                    }

                    Section {
                        HStack {
                            Text(languageManager.tr("Version", "Version", "Versión"))
                            Spacer()
                            Text("2.2")
                                .foregroundStyle(CheerUpColors.mutedSilver)
                        }
                    } header: {
                        Text(languageManager.tr("ABOUT", "À PROPOS", "ACERCA DE"))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(languageManager.tr("Settings", "Réglages", "Ajustes"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await NotificationManager.shared.refreshAuthorizationStatus()
                if NotificationManager.shared.authorizationStatus == .denied {
                    notificationsEnabled = false
                } else {
                    notificationsEnabled = NotificationManager.shared.isEnabled
                }
            }
            .alert(
                languageManager.tr("Notifications Disabled", "Notifications désactivées", "Notificaciones desactivadas"),
                isPresented: $showNotificationDeniedAlert
            ) {
                Button(languageManager.tr("Open Settings", "Ouvrir les réglages", "Abrir Ajustes")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                Button(languageManager.tr("Cancel", "Annuler", "Cancelar"), role: .cancel) {}
            } message: {
                Text(languageManager.tr(
                    "Enable notifications in iOS Settings to get a reminder every two days.",
                    "Active les notifications dans les réglages iOS pour recevoir un rappel tous les deux jours.",
                    "Activa las notificaciones en los ajustes de iOS para recibir un recordatorio cada dos días."
                ))
            }
        }
        .tint(CheerUpColors.lightGrey)
    }
}
