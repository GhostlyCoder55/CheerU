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
    var statement: String = "THE CONSTRAINT"
    var lessonDetail: String = "Choose carefully. One value must always be sacrificed."

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
            statement = "FAST & GOOD"
            lessonDetail = "High quality delivered quickly. It will be expensive (CHEAP sacrificed)."
        } else if isGood && isCheap {
            statement = "GOOD & CHEAP"
            lessonDetail = "Affordable and crafted with care. It will take time (FAST sacrificed)."
        } else if isFast && isCheap {
            statement = "FAST & CHEAP"
            lessonDetail = "Speedy and budget-friendly. Quality will suffer (GOOD sacrificed)."
        } else if isFast {
            statement = "ONLY FAST"
            lessonDetail = "Pure speed without quality or budget control leads to rushed waste."
        } else if isGood {
            statement = "ONLY GOOD"
            lessonDetail = "Perfection in a vacuum requires unlimited patience or endless money."
        } else if isCheap {
            statement = "ONLY CHEAP"
            lessonDetail = "Low cost alone means slow delivery and compromised standards."
        } else {
            statement = "THE CONSTRAINT"
            lessonDetail = "Choose carefully. One value must always be sacrificed."
        }
    }

    func reset() {
        isFast = false
        isGood = false
        isCheap = false
        sacrificedValue = nil
        statement = "THE CONSTRAINT"
        lessonDetail = "Choose carefully. One value must always be sacrificed."
        AudioManager.shared.play(.switchOff)
    }
}
