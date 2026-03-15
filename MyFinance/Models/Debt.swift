import Foundation
import SwiftData

@Model
final class Debt {
    var id: UUID
    var kpiAdi: String = ""           // Kime verildi
    var tip: String = ""              // Gram Altın, Çeyrek Altın, vs.
    var miktar: Double = 0           // Adet/Miktar
    var birimTutar: Double = 0       // Birim fiyat
    var toplamTutar: Double = 0      // miktar * birimTutar
    var paraBirimi: String = "TL"    // TL, USD, EUR
    var verilenTarih: Date = Date()  // Verildiği tarih
    var durum: String = "Açık"       // Açık, Kısmi, Tamamlandı
    var notlar: String?

    // Eski alanlar (migration uyumu için)
    var verilenTutar: Double = 0
    var adet: Double = 0
    var birimFiyat: Double = 0
    var alindigiTarih: Date?
    var geriAlimBirimFiyat: Double?
    var geriAlimToplamTutar: Double?

    @Relationship(deleteRule: .cascade)
    var odemeler: [DebtPayment]

    init(
        kpiAdi: String,
        tip: String,
        miktar: Double,
        birimTutar: Double,
        paraBirimi: String = "TL",
        verilenTarih: Date = Date(),
        notlar: String? = nil
    ) {
        self.id = UUID()
        self.kpiAdi = kpiAdi
        self.tip = tip
        self.miktar = miktar
        self.birimTutar = birimTutar
        self.toplamTutar = miktar * birimTutar
        self.paraBirimi = paraBirimi
        self.verilenTarih = verilenTarih
        self.durum = BorcDurum.acik.rawValue
        self.notlar = notlar
        self.odemeler = []

        // Eski alanlar
        self.verilenTutar = miktar * birimTutar
        self.adet = miktar
        self.birimFiyat = birimTutar
    }

    // Toplam ödeme tutarı
    var genelOdemeTutari: Double {
        odemeler.reduce(0) { $0 + $1.toplamTutar }
    }

    // Kalan borç
    var kalanBorc: Double {
        toplamTutar - genelOdemeTutari
    }

    // Otomatik durum hesaplama
    var hesaplananDurum: BorcDurum {
        if genelOdemeTutari <= 0 {
            return .acik
        } else if genelOdemeTutari >= toplamTutar {
            return .tamamlandi
        } else {
            return .kismi
        }
    }

    // Ödeme yüzdesi
    var odemeYuzdesi: Double {
        guard toplamTutar > 0 else { return 0 }
        return min((genelOdemeTutari / toplamTutar) * 100, 100)
    }

    // Eski uyumluluk
    var isReturned: Bool {
        durum == BorcDurum.tamamlandi.rawValue
    }

    var fark: Double? {
        guard genelOdemeTutari > 0 else { return nil }
        return genelOdemeTutari - toplamTutar
    }

    var farkYuzdesi: Double? {
        guard let fark, toplamTutar > 0 else { return nil }
        return (fark / toplamTutar) * 100
    }

    // Durumu güncelle
    func durumGuncelle() {
        durum = hesaplananDurum.rawValue
    }
}

@Model
final class DebtPayment {
    var id: UUID
    var tarih: Date = Date()
    var miktar: Double = 0
    var birimTutar: Double = 0
    var toplamTutar: Double = 0
    var notlar: String?

    var debt: Debt?

    init(
        tarih: Date = Date(),
        miktar: Double,
        birimTutar: Double,
        notlar: String? = nil
    ) {
        self.id = UUID()
        self.tarih = tarih
        self.miktar = miktar
        self.birimTutar = birimTutar
        self.toplamTutar = miktar * birimTutar
        self.notlar = notlar
    }
}
