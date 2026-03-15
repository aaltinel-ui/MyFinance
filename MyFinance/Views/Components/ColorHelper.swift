import SwiftUI

extension Color {
    static func forType(_ tip: String) -> Color {
        switch tip {
        case BirimTip.hisse.rawValue: return .blue
        case BirimTip.coin.rawValue: return .orange
        case BirimTip.altin.rawValue: return .yellow
        case BirimTip.fon.rawValue: return .green
        case BirimTip.maas.rawValue: return .teal
        case BirimTip.promosyon.rawValue: return .pink
        case BirimTip.emeklilikVadesiz.rawValue: return .indigo
        case BirimTip.bes.rawValue: return .purple
        case BirimTip.vadeli.rawValue: return .brown
        case BirimTip.nakit.rawValue: return .gray
        default: return .secondary
        }
    }

    static func forKasa(_ kasa: String) -> Color {
        switch kasa {
        case KasaTip.birikim.rawValue: return .blue
        case KasaTip.arabaParasi.rawValue: return .green
        case KasaTip.emeklilik.rawValue: return .purple
        case KasaTip.prim.rawValue: return .orange
        case KasaTip.maas.rawValue: return .teal
        default: return .secondary
        }
    }

    static let chartColors: [Color] = [
        .yellow, .blue, .orange, .green, .purple, .pink, .teal, .indigo, .brown, .cyan
    ]
}
