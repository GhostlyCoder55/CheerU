import SwiftUI

// MARK: - TRADE OFF Models
// An interactive constraint visualizer demonstrating that you cannot have all three.

enum TradeOffValue: String, CaseIterable, Identifiable {
    case fast = "fast"
    case good = "good"
    case cheap = "cheap"

    var id: String { rawValue }

    var label: String {
        let isFr = LanguageManager.shared.isFrench
        switch self {
        case .fast:  return isFr ? "RAPIDE" : "FAST"
        case .good:  return isFr ? "BON" : "GOOD"
        case .cheap: return isFr ? "PAS CHER" : "CHEAP"
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
