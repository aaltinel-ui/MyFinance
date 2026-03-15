import Foundation
import SwiftData

@Model
final class Debt {
    var id: UUID
    var verilenTarih: Date
    var verilenTutar: Double
    var tip: String
    var adet: Double
    var birimFiyat: Double
    var toplamTutar: Double
    var alindigiTarih: Date?
    var geriAlimBirimFiyat: Double?
    var geriAlimToplamTutar: Double?
    var kpiAdi: String?
    var notlar: String?

    init(
        verilenTarih: Date,
        verilenTutar: Double,
        tip: String,
        adet: Double,
        birimFiyat: Double,
        kpiAdi: String? = nil,
        notlar: String? = nil
    ) {
        self.id = UUID()
        self.verilenTarih = verilenTarih
        self.verilenTutar = verilenTutar
        self.tip = tip
        self.adet = adet
        self.birimFiyat = birimFiyat
        self.toplamTutar = adet * birimFiyat
        self.kpiAdi = kpiAdi
        self.notlar = notlar
    }

    var isReturned: Bool {
        alindigiTarih != nil
    }

    var fark: Double? {
        guard let geriAlimToplamTutar else { return nil }
        return geriAlimToplamTutar - toplamTutar
    }

    var farkYuzdesi: Double? {
        guard let fark, toplamTutar > 0 else { return nil }
        return (fark / toplamTutar) * 100
    }
}
