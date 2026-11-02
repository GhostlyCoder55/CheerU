import SwiftUI

// MARK: - App Language
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case french = "fr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .french:  return "Français"
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

    func tr(_ en: String, _ fr: String) -> String {
        isFrench ? fr : en
    }
}
