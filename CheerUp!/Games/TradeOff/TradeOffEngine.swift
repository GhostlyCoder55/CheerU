import SwiftUI

// MARK: - TRADE OFF Engine
// Implements the interactive constraint logic from theTradeOff.html:
// "Choose carefully. One value must always be sacrificed."

@Observable
final class TradeOffEngine {
    var isFast: Bool = false
    var isGood: Bool = false
    var isCheap: Bool = false

    var sacrificedValue: TradeOffValue? = nil
    var statement: String = LanguageManager.shared.tr("PICK TWO", "CHOISISSEZ DEUX", "ELIGE DOS")
    var lessonDetail: String = LanguageManager.shared.tr("One value is always sacrificed.", "Une valeur est toujours sacrifiée.", "Un valor siempre se sacrifica.")

    func toggle(_ value: TradeOffValue) {
        let turningOn: Bool
        sacrificedValue = nil

        switch value {
        case .fast:
            turningOn = !isFast
            isFast = turningOn
        case .good:
            turningOn = !isGood
            isGood = turningOn
        case .cheap:
            turningOn = !isCheap
            isCheap = turningOn
        }

        HapticsManager.shared.lightTap()
        if turningOn {
            AudioManager.shared.play(.switchToggle)
        } else {
            AudioManager.shared.play(.switchOff)
        }

        // Exact paradox logic from theTradeOff.html
        if isFast && isGood && isCheap {
            // Mechanical constraint snap
            HapticsManager.shared.heavyImpact()
            AudioManager.shared.play(.bounce)

            switch value {
            case .fast:
                isCheap = false
                sacrificedValue = .cheap
            case .good:
                isFast = false
                sacrificedValue = .fast
            case .cheap:
                isGood = false
                sacrificedValue = .good
            }
        }

        updateLesson()
    }

    private func updateLesson() {
        if isFast && isGood {
            statement = LanguageManager.shared.tr("FAST & GOOD", "RAPIDE & BON", "RÁPIDO Y BUENO")
            lessonDetail = LanguageManager.shared.tr("Great and fast, but expensive.", "Super et rapide, mais cher.", "Genial y rápido, pero caro.")
        } else if isGood && isCheap {
            statement = LanguageManager.shared.tr("GOOD & CHEAP", "BON & PAS CHER", "BUENO Y BARATO")
            lessonDetail = LanguageManager.shared.tr("Great and cheap, but slow.", "Super et pas cher, mais lent.", "Genial y barato, pero lento.")
        } else if isFast && isCheap {
            statement = LanguageManager.shared.tr("FAST & CHEAP", "RAPIDE & PAS CHER", "RÁPIDO Y BARATO")
            lessonDetail = LanguageManager.shared.tr("Fast and cheap, but low quality.", "Rapide et pas cher, mais médiocre.", "Rápido y barato, pero mediocre.")
        } else if isFast {
            statement = LanguageManager.shared.tr("ONLY FAST", "JUSTE RAPIDE", "SOLO RÁPIDO")
            lessonDetail = LanguageManager.shared.tr("Speed alone leads to rushed mistakes.", "La vitesse seule crée des erreurs.", "La velocidad sola genera errores.")
        } else if isGood {
            statement = LanguageManager.shared.tr("ONLY GOOD", "JUSTE BON", "SOLO BUENO")
            lessonDetail = LanguageManager.shared.tr("Quality alone takes forever or costs a fortune.", "La qualité seule prend du temps.", "La calidad sola toma tiempo o dinero.")
        } else if isCheap {
            statement = LanguageManager.shared.tr("ONLY CHEAP", "JUSTE PAS CHER", "SOLO BARATO")
            lessonDetail = LanguageManager.shared.tr("Cheap alone means slow delivery and poor quality.", "Le pas cher seul est lent et bâclé.", "Lo barato solo es lento y deficiente.")
        } else {
            statement = LanguageManager.shared.tr("PICK TWO", "CHOISISSEZ DEUX", "ELIGE DOS")
            lessonDetail = LanguageManager.shared.tr("One value is always sacrificed.", "Une valeur est toujours sacrifiée.", "Un valor siempre se sacrifica.")
        }
    }

    func reset() {
        isFast = false
        isGood = false
        isCheap = false
        sacrificedValue = nil
        statement = LanguageManager.shared.tr("PICK TWO", "CHOISISSEZ DEUX", "ELIGE DOS")
        lessonDetail = LanguageManager.shared.tr("One value is always sacrificed.", "Une valeur est toujours sacrifiée.", "Un valor siempre se sacrifica.")
        AudioManager.shared.play(.switchOff)
    }
}
