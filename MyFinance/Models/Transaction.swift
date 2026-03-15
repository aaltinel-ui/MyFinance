import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var tarih: Date
    var kasaTip: String
    var islem: String
    var tip: String
    var nerede: String
    var guncellenecekMi: Bool
    var yon: String
    var birimFiyat: Double
    var adet: Double
    var tutarTL: Double
    var notlar: String?

    init(
        tarih: Date,
        kasaTip: KasaTip,
        islem: String,
        tip: BirimTip,
        nerede: SaklamaYeri,
        guncellenecekMi: Bool = true,
        yon: HareketYon,
        birimFiyat: Double,
        adet: Double,
        notlar: String? = nil
    ) {
        self.id = UUID()
        self.tarih = tarih
        self.kasaTip = kasaTip.rawValue
        self.islem = islem
        self.tip = tip.rawValue
        self.nerede = nerede.rawValue
        self.guncellenecekMi = guncellenecekMi
        self.yon = yon.rawValue
        self.birimFiyat = birimFiyat
        self.adet = adet
        self.tutarTL = birimFiyat * adet
        self.notlar = notlar
    }

    var kasaTipEnum: KasaTip? { KasaTip(rawValue: kasaTip) }
    var tipEnum: BirimTip? { BirimTip(rawValue: tip) }
    var neredeEnum: SaklamaYeri? { SaklamaYeri(rawValue: nerede) }
    var yonEnum: HareketYon? { HareketYon(rawValue: yon) }

    var isPositive: Bool {
        yonEnum?.isPositive ?? true
    }

    var signedTutar: Double {
        isPositive ? tutarTL : -tutarTL
    }

    var signedAdet: Double {
        isPositive ? adet : -adet
    }
}
