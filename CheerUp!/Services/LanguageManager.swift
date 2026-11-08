import SwiftUI

// MARK: - App Language
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case french = "fr"
    case spanish = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .french:  return "Français"
        case .spanish: return "Español"
        }
    }
}

// MARK: - Language Manager
@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    private static let languageKey = "cheerup.language"
    private static let onboardingCompletedKey = "cheerup.language.onboarded"

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.languageKey)
        }
    }

    var hasCompletedLanguageOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedLanguageOnboarding, forKey: Self.onboardingCompletedKey)
        }
    }

    private init() {
        let completed = UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
        self.hasCompletedLanguageOnboarding = completed

        if let saved = UserDefaults.standard.string(forKey: Self.languageKey),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            self.currentLanguage = .english
        }
    }

    func selectInitialLanguage(_ language: AppLanguage) {
        currentLanguage = language
        hasCompletedLanguageOnboarding = true
    }

    var isFrench: Bool {
        currentLanguage == .french
    }

    var isSpanish: Bool {
        currentLanguage == .spanish
    }

    func tr(_ en: String, _ fr: String, _ es: String? = nil) -> String {
        switch currentLanguage {
        case .french:
            return fr
        case .spanish:
            return es ?? en
        case .english:
            return en
        }
    }
}
