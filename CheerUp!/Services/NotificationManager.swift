import Foundation
import SwiftUI
import UserNotifications

// MARK: - Notification Manager
// Schedules a short local reminder every two days of inactivity to invite the user back into CheerUp!.

@Observable
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    static let reminderIdentifier = "cheerup.reminder.twoDays"
    static let twoDaysInterval: TimeInterval = 2 * 24 * 60 * 60 // 48 hours

    private static let enabledKey = "cheerup.notifications.enabled"
    private static let requestedKey = "cheerup.notifications.requested"

    private let center: UNUserNotificationCenter

    private(set) var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
        }
    }

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var isAuthorized: Bool {
        authorizationStatus == .authorized
            || authorizationStatus == .provisional
            || authorizationStatus == .ephemeral
    }

    private var hasRequestedPermission: Bool {
        get { UserDefaults.standard.bool(forKey: Self.requestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.requestedKey) }
    }

    // MARK: - Trilingual Short Reminder Messages

    struct ReminderMessage {
        let en: String
        let fr: String
        let es: String

        func body(for language: AppLanguage) -> String {
            switch language {
            case .english: return en
            case .french:  return fr
            case .spanish: return es
            }
        }
    }

    static let reminderMessages: [ReminderMessage] = [
        ReminderMessage(
            en: "Ready for a quick round? Jump back in!",
            fr: "Prêt pour une partie rapide ? Reviens jouer !",
            es: "¿Listo para una partida rápida? ¡Vuelve a jugar!"
        ),
        ReminderMessage(
            en: "Time for a quick CheerUp! Can you beat your high score?",
            fr: "L'heure d'un petit CheerUp! Tu bats ton record ?",
            es: "¡Hora de un CheerUp! ¿Superas tu récord?"
        ),
        ReminderMessage(
            en: "MiniCheerUp! misses you — jump back into the arcade!",
            fr: "MiniCheerUp! t'attend — reviens dans l'arcade !",
            es: "¡MiniCheerUp! te espera — ¡vuelve al arcade!"
        ),
        ReminderMessage(
            en: "Got 2 minutes? Tap, bounce, and rush back in!",
            fr: "2 minutes de libre ? Viens faire une partie !",
            es: "¿Tienes 2 minutos? ¡Vuelve a jugar un rato!"
        )
    ]

    // MARK: - Initialization

    private init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        if UserDefaults.standard.object(forKey: Self.enabledKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.enabledKey)
        }
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    // MARK: - Authorization & Scheduling

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Prompts for notification permission once after onboarding, then schedules the 2-day reminder if granted.
    func requestAuthorizationIfNeeded() async {
        await refreshAuthorizationStatus()

        if authorizationStatus == .notDetermined && !hasRequestedPermission {
            hasRequestedPermission = true
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await refreshAuthorizationStatus()
                if granted && isEnabled {
                    scheduleTwoDayReminder()
                }
            } catch {
                await refreshAuthorizationStatus()
            }
        } else if isAuthorized && isEnabled {
            scheduleTwoDayReminder()
        }
    }

    /// Enables or disables the 2-day reminder. Returns `false` if system notification permission is denied.
    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        isEnabled = enabled

        guard enabled else {
            cancelPendingReminders()
            return true
        }

        await refreshAuthorizationStatus()

        if authorizationStatus == .notDetermined {
            hasRequestedPermission = true
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await refreshAuthorizationStatus()
                if granted {
                    scheduleTwoDayReminder()
                    return true
                } else {
                    isEnabled = false
                    return false
                }
            } catch {
                isEnabled = false
                return false
            }
        }

        if isAuthorized {
            scheduleTwoDayReminder()
            return true
        }

        // System permission was previously denied
        isEnabled = false
        return false
    }

    /// Resets the 48-hour inactivity timer when the app becomes active or moves to the background.
    func refreshScheduleIfNeeded() async {
        guard isEnabled else {
            cancelPendingReminders()
            return
        }

        await refreshAuthorizationStatus()
        guard isAuthorized else { return }

        scheduleTwoDayReminder()
    }

    /// Schedules a repeating local notification every 2 days (48 hours).
    func scheduleTwoDayReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])

        let content = makeReminderContent(for: LanguageManager.shared.currentLanguage)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Self.twoDaysInterval,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: Self.reminderIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func cancelPendingReminders() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
    }

    // MARK: - Content Builder

    func makeReminderContent(for language: AppLanguage, index: Int? = nil) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "CheerUp!"

        let message: ReminderMessage
        if let index, Self.reminderMessages.indices.contains(index) {
            message = Self.reminderMessages[index]
        } else {
            message = Self.reminderMessages.randomElement() ?? Self.reminderMessages[0]
        }

        content.body = message.body(for: language)
        content.sound = .default
        return content
    }
}
