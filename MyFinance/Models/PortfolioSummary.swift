import Foundation

struct PortfolioSummary {
    var toplamDeger: Double = 0
    var toplamMaliyet: Double = 0
    var karZarar: Double { toplamDeger - toplamMaliyet }
    var karZararYuzdesi: Double {
        guard toplamMaliyet > 0 else { return 0 }
        return (karZarar / toplamMaliyet) * 100
    }
}

struct InstrumentPosition: Identifiable {
    let id = UUID()
    let islem: String
    let tip: String
    let kasaTip: String
    var toplamAdet: Double
    var toplamMaliyet: Double
    var ortalamaAlisFiyati: Double {
        guard toplamAdet > 0 else { return 0 }
        return toplamMaliyet / toplamAdet
    }
    var guncelFiyat: Double
    var guncelDeger: Double { toplamAdet * guncelFiyat }
    var karZarar: Double { guncelDeger - toplamMaliyet }
    var karZararYuzdesi: Double {
        guard toplamMaliyet > 0 else { return 0 }
        return (karZarar / toplamMaliyet) * 100
    }
    var isKarda: Bool { karZarar >= 0 }
}

struct TypeSummary: Identifiable {
    let id = UUID()
    let tip: String
    var toplamMaliyet: Double
    var guncelDeger: Double
    var karZarar: Double { guncelDeger - toplamMaliyet }
    var karZararYuzdesi: Double {
        guard toplamMaliyet > 0 else { return 0 }
        return (karZarar / toplamMaliyet) * 100
    }
}

struct KasaSummary: Identifiable {
    let id = UUID()
    let kasaTip: String
    var toplamMaliyet: Double
    var guncelDeger: Double
    var karZarar: Double { guncelDeger - toplamMaliyet }
    var karZararYuzdesi: Double {
        guard toplamMaliyet > 0 else { return 0 }
        return (karZarar / toplamMaliyet) * 100
    }
    var positions: [InstrumentPosition]
}
