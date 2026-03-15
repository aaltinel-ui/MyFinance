import Foundation
import SwiftData

@Model
final class ChildExpense {
    var id: UUID
    var yil: Int = 0
    var tarih: Date
    var cocukAdi: String
    var kategori: String
    var aciklama: String
    var tutar: Double = 0          // TL tutarı
    var eurDegeri: Double = 0      // EUR karşılığı
    var kur: Double = 0            // EUR/TL kuru
    var notlar: String?

    init(
        yil: Int = Calendar.current.component(.year, from: Date()),
        tarih: Date = Date(),
        cocukAdi: String,
        kategori: String,
        aciklama: String,
        tutar: Double,
        eurDegeri: Double = 0,
        kur: Double = 0,
        notlar: String? = nil
    ) {
        self.id = UUID()
        self.yil = yil
        self.tarih = tarih
        self.cocukAdi = cocukAdi
        self.kategori = kategori
        self.aciklama = aciklama
        self.tutar = tutar
        self.eurDegeri = eurDegeri
        self.kur = kur > 0 ? kur : (eurDegeri > 0 ? tutar / eurDegeri : 0)
        self.notlar = notlar
    }
}
