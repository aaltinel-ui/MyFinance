import Foundation
import SwiftData

@Model
final class FitreZekat {
    var id: UUID
    var tarih: Date = Date()
    var tur: String = ""        // "Fitre" veya "Zekât"
    var kisiAdi: String = ""
    var tutar: Double = 0
    var aciklama: String = ""
    var notlar: String?

    init(
        tarih: Date = Date(),
        tur: String,
        kisiAdi: String,
        tutar: Double,
        aciklama: String = "",
        notlar: String? = nil
    ) {
        self.id = UUID()
        self.tarih = tarih
        self.tur = tur
        self.kisiAdi = kisiAdi
        self.tutar = tutar
        self.aciklama = aciklama
        self.notlar = notlar
    }
}
