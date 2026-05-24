import Foundation
import SwiftData

@Model
final class BESHesap {
    var id: UUID
    var sirketAdi: String
    var planAdi: String
    var hesapNo: String
    var baslangicTarihi: Date
    var birikimTutari: Double
    var devletKatkisi: Double
    var sirketKatkisi: Double
    var fonDegeri: Double
    var notlar: String?

    init(
        sirketAdi: String,
        planAdi: String,
        hesapNo: String = "",
        baslangicTarihi: Date = Date(),
        birikimTutari: Double = 0,
        devletKatkisi: Double = 0,
        sirketKatkisi: Double = 0,
        fonDegeri: Double = 0,
        notlar: String? = nil
    ) {
        self.id = UUID()
        self.sirketAdi = sirketAdi
        self.planAdi = planAdi
        self.hesapNo = hesapNo
        self.baslangicTarihi = baslangicTarihi
        self.birikimTutari = birikimTutari
        self.devletKatkisi = devletKatkisi
        self.sirketKatkisi = sirketKatkisi
        self.fonDegeri = fonDegeri
        self.notlar = notlar
    }

    var toplamDeger: Double {
        birikimTutari + devletKatkisi + sirketKatkisi + fonDegeri
    }
}
