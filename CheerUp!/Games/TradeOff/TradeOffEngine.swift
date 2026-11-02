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
    var statement: String = LanguageManager.shared.tr("PICK TWO", "CHOISISSEZ DEUX")
    var lessonDetail: String = LanguageManager.shared.tr("One value is always sacrificed.", "Une valeur est toujours sacrifiée.")

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
        let isFr = LanguageManager.shared.isFrench
        if isFast && isGood {
            statement = isFr ? "RAPIDE & BON" : "FAST & GOOD"
            lessonDetail = isFr ? "Super et rapide, mais cher." : "Great and fast, but expensive."
        } else if isGood && isCheap {
            statement = isFr ? "BON & PAS CHER" : "GOOD & CHEAP"
            lessonDetail = isFr ? "Super et pas cher, mais lent." : "Great and cheap, but slow."
        } else if isFast && isCheap {
            statement = isFr ? "RAPIDE & PAS CHER" : "FAST & CHEAP"
            lessonDetail = isFr ? "Rapide et pas cher, mais médiocre." : "Fast and cheap, but low quality."
        } else if isFast {
            statement = isFr ? "JUSTE RAPIDE" : "ONLY FAST"
            lessonDetail = isFr ? "La vitesse seule crée des erreurs." : "Speed alone leads to rushed mistakes."
        } else if isGood {
            statement = isFr ? "JUSTE BON" : "ONLY GOOD"
            lessonDetail = isFr ? "La qualité seule prend du temps." : "Quality alone takes forever or costs a fortune."
        } else if isCheap {
            statement = isFr ? "JUSTE PAS CHER" : "ONLY CHEAP"
            lessonDetail = isFr ? "Le pas cher seul est lent et bâclé." : "Cheap alone means slow delivery and poor quality."
        } else {
            statement = isFr ? "CHOISISSEZ DEUX" : "PICK TWO"
            lessonDetail = isFr ? "Une valeur est toujours sacrifiée." : "One value is always sacrificed."
        }
    }

    func reset() {
        let isFr = LanguageManager.shared.isFrench
        isFast = false
        isGood = false
        isCheap = false
        sacrificedValue = nil
        statement = isFr ? "CHOISISSEZ DEUX" : "PICK TWO"
        lessonDetail = isFr ? "Une valeur est toujours sacrifiée." : "One value is always sacrificed."
        AudioManager.shared.play(.switchOff)
    }
}
