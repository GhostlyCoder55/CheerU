import SwiftUI

// MARK: - TRADE OFF Models
// An interactive constraint visualizer demonstrating that you cannot have all three.

enum TradeOffValue: String, CaseIterable, Identifiable {
    case fast = "fast"
    case good = "good"
    case cheap = "cheap"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fast:  return LanguageManager.shared.tr("FAST", "RAPIDE", "RÁPIDO")
        case .good:  return LanguageManager.shared.tr("GOOD", "BON", "BUENO")
        case .cheap: return LanguageManager.shared.tr("CHEAP", "PAS CHER", "BARATO")
        }
    }

    var activeColor: Color {
        switch self {
        case .fast:  return CheerUpColors.TradeOff.fast   // #EF5350 Red
        case .good:  return CheerUpColors.TradeOff.good   // #66BB6A Green
        case .cheap: return CheerUpColors.TradeOff.cheap  // #42A5F5 Blue
        }
    }
}
