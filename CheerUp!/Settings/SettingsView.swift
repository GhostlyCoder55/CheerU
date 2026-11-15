import SwiftUI
import UIKit

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @State private var soundEnabled: Bool = AudioManager.shared.isEnabled
    @State private var hapticsEnabled: Bool = HapticsManager.shared.isEnabled
    @State private var notificationsEnabled: Bool = NotificationManager.shared.isEnabled
    @State private var showNotificationDeniedAlert = false
    @State private var appeared = false
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                // Seamless Header (no NavigationBar hairline or translucent step)
                Text(languageManager.tr("Settings", "Réglages", "Ajustes"))
                    .font(CheerUpFont.title3)
                    .foregroundStyle(CheerUpColors.lightGrey)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 22)
                    .padding(.bottom, 2)

                // PREFERENCES Section
                settingsSection(
                    title: languageManager.tr("PREFERENCES", "PRÉFÉRENCES", "PREFERENCIAS")
                ) {
                    VStack(spacing: 0) {
                        settingsToggleRow(
                            title: languageManager.tr("Sound Effects", "Sons", "Sonidos"),
                            systemImage: "speaker.wave.2.fill",
                            isOn: $soundEnabled
                        )
                        .onChange(of: soundEnabled) { _, newValue in
                            AudioManager.shared.setEnabled(newValue)
                        }

                        rowDivider

                        settingsToggleRow(
                            title: languageManager.tr("Haptic Feedback", "Vibrations", "Vibración"),
                            systemImage: "hand.tap.fill",
                            isOn: $hapticsEnabled
                        )
                        .onChange(of: hapticsEnabled) { _, newValue in
                            HapticsManager.shared.setEnabled(newValue)
                        }

                        rowDivider

                        settingsToggleRow(
                            title: languageManager.tr("Play Reminders", "Rappels de jeu", "Recordatorios"),
                            systemImage: "bell.badge.fill",
                            isOn: $notificationsEnabled
                        )
                        .onChange(of: notificationsEnabled) { _, newValue in
                            Task {
                                let success = await NotificationManager.shared.setEnabled(newValue)
                                if !success && newValue {
                                    notificationsEnabled = false
                                    showNotificationDeniedAlert = true
                                }
                            }
                        }
                    }
                }

                // LANGUAGE Section
                settingsSection(
                    title: languageManager.tr("LANGUAGE", "LANGUE", "IDIOMA")
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(CheerUpColors.mutedSilver)
                            .frame(width: 24)

                        Text(languageManager.tr("Language", "Langue", "Idioma"))
                            .font(CheerUpFont.body)
                            .foregroundStyle(CheerUpColors.lightGrey)

                        Spacer()

                        Picker(selection: $languageManager.currentLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        } label: {
                            EmptyView()
                        }
                        .pickerStyle(.menu)
                        .tint(CheerUpColors.mutedSilver)
                        .onChange(of: languageManager.currentLanguage) { _, _ in
                            HapticsManager.shared.selection()
                            Task {
                                await NotificationManager.shared.refreshScheduleIfNeeded()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                // ABOUT Section
                settingsSection(
                    title: languageManager.tr("ABOUT", "À PROPOS", "ACERCA DE")
                ) {
                    HStack(spacing: 12) {
                        Text(languageManager.tr("Version", "Version", "Versión"))
                            .font(CheerUpFont.body)
                            .foregroundStyle(CheerUpColors.lightGrey)

                        Spacer()

                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.3")
                            .font(CheerUpFont.body)
                            .foregroundStyle(CheerUpColors.mutedSilver)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(.easeOut(duration: 0.28), value: appeared)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.clear)
        .tint(CheerUpColors.lightGrey)
        .onAppear {
            appeared = true
        }
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

    // MARK: - Section Card Builder
    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(CheerUpFont.caption)
                .foregroundStyle(CheerUpColors.mutedSilver.opacity(0.85))
                .tracking(1.1)
                .padding(.horizontal, 12)

            content()
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(CheerUpColors.blueGrey.opacity(0.28))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
        }
    }

    // MARK: - Toggle Row Helper
    private func settingsToggleRow(
        title: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn.animation(.spring(response: 0.28, dampingFraction: 0.8))) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CheerUpColors.mutedSilver)
                    .frame(width: 24)

                Text(title)
                    .font(CheerUpFont.body)
                    .foregroundStyle(CheerUpColors.lightGrey)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 52)
            .padding(.trailing, 16)
    }
}
