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

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "cheerup.language")
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "cheerup.language"),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            self.currentLanguage = .english
        }
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
