import Foundation

enum KasaTip: String, Codable, CaseIterable, Identifiable {
    case birikim = "Birikim"
    case arabaParasi = "ArabaParası"
    case emeklilik = "Emeklilik"
    case prim = "Prim"
    case maas = "Maaş"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .birikim: return "banknote"
        case .arabaParasi: return "car"
        case .emeklilik: return "person.crop.circle.badge.clock"
        case .prim: return "gift"
        case .maas: return "briefcase"
        }
    }

    var color: String {
        switch self {
        case .birikim: return "blue"
        case .arabaParasi: return "green"
        case .emeklilik: return "purple"
        case .prim: return "orange"
        case .maas: return "teal"
        }
    }
}

enum BirimTip: String, Codable, CaseIterable, Identifiable {
    case hisse = "HİSSE"
    case coin = "COIN"
    case altin = "ALTIN"
    case fon = "FON"
    case maas = "Maaş"
    case promosyon = "Promosyon"
    case emeklilikVadesiz = "EmeklilikVadesiz"
    case bes = "BES"
    case vadeli = "VADELİ"
    case nakit = "NAKİT"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hisse: return "chart.line.uptrend.xyaxis"
        case .coin: return "bitcoinsign.circle"
        case .altin: return "circle.fill"
        case .fon: return "chart.pie"
        case .maas: return "briefcase"
        case .promosyon: return "gift"
        case .emeklilikVadesiz: return "clock"
        case .bes: return "building.columns"
        case .vadeli: return "lock.circle"
        case .nakit: return "turkishlirasign.circle"
        }
    }

    var displayColor: String {
        switch self {
        case .hisse: return "blue"
        case .coin: return "orange"
        case .altin: return "yellow"
        case .fon: return "green"
        case .maas: return "teal"
        case .promosyon: return "pink"
        case .emeklilikVadesiz: return "indigo"
        case .bes: return "purple"
        case .vadeli: return "brown"
        case .nakit: return "gray"
        }
    }
}

enum SaklamaYeri: String, Codable, CaseIterable, Identifiable {
    case banka = "Banka"
    case binanceTR = "BINANCETR"
    case evde = "Evde"
    case babam = "BABAM"

    var id: String { rawValue }
}

enum HareketYon: String, Codable, CaseIterable, Identifiable {
    case arti = "+"
    case eksi = "-"
    case alindi = "Alındı"
    case satildi = "Satıldı"

    var id: String { rawValue }

    var isPositive: Bool {
        switch self {
        case .arti, .alindi: return true
        case .eksi, .satildi: return false
        }
    }
}

enum GelirKategorisi: String, Codable, CaseIterable, Identifiable {
    case maas = "Maaş"
    case emekliMaasi = "Emekli Maaşı"
    case temettu = "Temettü"
    case kira = "Kira"
    case diger = "Diğer"

    var id: String { rawValue }
}
