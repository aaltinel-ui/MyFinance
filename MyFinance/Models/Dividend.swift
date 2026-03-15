import Foundation
import SwiftData

@Model
final class Dividend {
    var id: UUID
    var tarih: Date
    var hisse: String
    var adet: Double
    var birimTemettu: Double
    var toplamTutar: Double
    var notlar: String?

    init(
        tarih: Date,
        hisse: String,
        adet: Double,
        birimTemettu: Double,
        notlar: String? = nil
    ) {
        self.id = UUID()
        self.tarih = tarih
        self.hisse = hisse
        self.adet = adet
        self.birimTemettu = birimTemettu
        self.toplamTutar = adet * birimTemettu
        self.notlar = notlar
    }
}
