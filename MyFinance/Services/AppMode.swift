import SwiftUI

enum AppMode: String, CaseIterable {
    case myFinans = "MyFinans"
    case borcTakibi = "Borç Takibi"
    case cocuklarim = "Çocuklarım"
    case fitreZekat = "Fitre/Zekât"
    case bes = "BES"

    var icon: String {
        switch self {
        case .myFinans:   return "chart.pie.fill"
        case .borcTakibi: return "arrow.left.arrow.right.circle.fill"
        case .cocuklarim: return "figure.2.and.child.holdinghands"
        case .fitreZekat: return "heart.circle.fill"
        case .bes:        return "building.columns.fill"
        }
    }

    var color: Color {
        switch self {
        case .myFinans:   return .blue
        case .borcTakibi: return .red
        case .cocuklarim: return .purple
        case .fitreZekat: return .green
        case .bes:        return .indigo
        }
    }
}
