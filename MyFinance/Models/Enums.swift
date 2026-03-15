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

enum CocukHarcamaKategori: String, Codable, CaseIterable, Identifiable {
    case egitim = "Eğitim"
    case saglik = "Sağlık"
    case giyim = "Giyim"
    case yiyecek = "Yiyecek"
    case oyuncak = "Oyuncak"
    case kurs = "Kurs"
    case muzik = "Müzik"
    case seyahat = "Seyahat"
    case paraTransferi = "Para Transferi"
    case ekipman = "Ekipman"
    case harçlık = "Harçlık"
    case diger = "Diğer"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .egitim: return "book.fill"
        case .saglik: return "cross.case.fill"
        case .giyim: return "tshirt.fill"
        case .yiyecek: return "fork.knife"
        case .oyuncak: return "gamecontroller.fill"
        case .kurs: return "person.3.fill"
        case .muzik: return "guitars.fill"
        case .seyahat: return "airplane"
        case .paraTransferi: return "arrow.left.arrow.right"
        case .ekipman: return "wrench.and.screwdriver.fill"
        case .harçlık: return "turkishlirasign.circle"
        case .diger: return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .egitim: return "blue"
        case .saglik: return "red"
        case .giyim: return "purple"
        case .yiyecek: return "orange"
        case .oyuncak: return "pink"
        case .kurs: return "teal"
        case .muzik: return "indigo"
        case .seyahat: return "cyan"
        case .paraTransferi: return "mint"
        case .ekipman: return "brown"
        case .harçlık: return "green"
        case .diger: return "gray"
        }
    }
}

enum BorcTipi: String, Codable, CaseIterable, Identifiable {
    case gramAltin = "Gram Altın"
    case ceyrekAltin = "Çeyrek Altın"
    case yarimAltin = "Yarım Altın"
    case cumhuriyetAltin = "Cumhuriyet Altın"
    case euro = "Euro"
    case usd = "USD"
    case tl = "TL"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gramAltin, .ceyrekAltin, .yarimAltin, .cumhuriyetAltin: return "circle.fill"
        case .euro: return "eurosign.circle"
        case .usd: return "dollarsign.circle"
        case .tl: return "turkishlirasign.circle"
        }
    }

    var color: String {
        switch self {
        case .gramAltin, .ceyrekAltin, .yarimAltin, .cumhuriyetAltin: return "yellow"
        case .euro: return "blue"
        case .usd: return "green"
        case .tl: return "red"
        }
    }
}

enum BorcDurum: String, Codable, CaseIterable, Identifiable {
    case acik = "Açık"
    case kismi = "Kısmi"
    case tamamlandi = "Tamamlandı"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .acik: return "clock.fill"
        case .kismi: return "chart.bar.fill"
        case .tamamlandi: return "checkmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .acik: return "orange"
        case .kismi: return "blue"
        case .tamamlandi: return "green"
        }
    }
}

enum ParaBirimi: String, Codable, CaseIterable, Identifiable {
    case tl = "TL"
    case usd = "USD"
    case eur = "EUR"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .tl: return "₺"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
}

enum FitreZekatTur: String, Codable, CaseIterable, Identifiable {
    case fitre = "Fitre"
    case zekat = "Zekât"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fitre: return "hand.raised.fill"
        case .zekat: return "heart.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .fitre: return "green"
        case .zekat: return "teal"
        }
    }
}
