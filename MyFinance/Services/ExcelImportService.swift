import Foundation
import SwiftData

// Excel import service that reads CSV-exported data from the Excel file
// The user should export each sheet as CSV and place them in the app's documents directory
@MainActor
class ExcelImportService {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func importAll() async throws -> String {
        var results: [String] = []

        let txCount = try importTransactions()
        results.append("\(txCount) hareket")

        let divCount = try importDividends()
        results.append("\(divCount) temettü")

        let debtCount = try importDebts()
        results.append("\(debtCount) borç")

        let rateCount = try importExchangeRates()
        results.append("\(rateCount) kur verisi")

        try context.save()
        return "Aktarıldı: \(results.joined(separator: ", "))"
    }

    func importTransactions() throws -> Int {
        // Import hardcoded data from the Excel analysis
        let data: [(tarih: String, kasaTip: String, islem: String, tip: String, nerede: String, guncelle: Bool, yon: String, birimFiyat: Double, adet: Double)] = [
            ("2024-09-12", "ArabaParası", "TUPRS", "HİSSE", "Banka", true, "+", 155.6, 1000),
            ("2024-09-12", "ArabaParası", "TUPRS", "HİSSE", "Banka", true, "+", 157, 500),
            ("2024-09-12", "ArabaParası", "TUPRS", "HİSSE", "Banka", true, "+", 156.4, 500),
            ("2024-09-16", "ArabaParası", "TUPRS", "HİSSE", "Banka", true, "+", 163.2, 500),
            ("2024-09-16", "ArabaParası", "TUPRS", "HİSSE", "Banka", true, "+", 162.9, 1000),
            ("2024-09-16", "ArabaParası", "TUPRS", "HİSSE", "Banka", true, "+", 162.8, 117),
            ("2024-09-17", "ArabaParası", "TUPRS", "HİSSE", "Banka", true, "+", 164, 1500),
            ("2024-09-20", "ArabaParası", "TUPRS", "HİSSE", "Banka", true, "+", 168.7, 700),
            ("2024-10-01", "ArabaParası", "ALTIN GRAM", "ALTIN", "BABAM", true, "+", 2959.84, 21.11),
            ("2024-10-01", "ArabaParası", "Cumhuriyet Altın", "ALTIN", "BABAM", true, "+", 9300, 1),
            ("2024-10-08", "ArabaParası", "TUPRS", "HİSSE", "Banka", true, "+", 164.5, 1500),
            ("2024-12-09", "ArabaParası", "TUPRS", "HİSSE", "Banka", true, "+", 131.3, 500),
            // Birikim - HİSSE
            ("2024-01-01", "Birikim", "TUPRS", "HİSSE", "Banka", true, "+", 140, 932),
            ("2024-01-01", "Birikim", "KCHOL", "HİSSE", "Banka", true, "+", 129.7, 200),
            ("2024-01-01", "Birikim", "AKBNK", "HİSSE", "Banka", true, "+", 44, 10),
            ("2024-01-01", "Birikim", "THYAO", "HİSSE", "Banka", true, "+", 280, 100),
            ("2024-03-09", "Birikim", "ALFAS", "HİSSE", "Banka", true, "+", 58.6, 100),
            ("2024-04-03", "Birikim", "THYAO", "HİSSE", "Banka", true, "-", 308, 100),
            ("2024-09-20", "Birikim", "KCHOL", "HİSSE", "Banka", true, "+", 171.5, 500),
            ("2024-10-08", "Birikim", "ARCLK", "HİSSE", "Banka", true, "+", 120, 100),
            ("2024-11-06", "Birikim", "ALFAS", "HİSSE", "Banka", true, "+", 54.5, 200),
            ("2025-04-04", "Birikim", "AKBNK", "HİSSE", "Banka", false, "+", 52.05, 190),
            ("2025-04-04", "Birikim", "AKBNK", "HİSSE", "Banka", false, "+", 52.3, 20),
            // Birikim - ALTIN
            ("2024-01-01", "Birikim", "ALTIN GRAM", "ALTIN", "Evde", true, "+", 1900, 19),
            ("2024-01-01", "Birikim", "Cumhuriyet Altın", "ALTIN", "Evde", true, "+", 7500, 5),
            ("2024-06-15", "Birikim", "ALTIN GRAM", "ALTIN", "BABAM", true, "+", 2500, 3),
            ("2024-10-01", "Birikim", "Cumhuriyet Altın", "ALTIN", "BABAM", true, "+", 18500, 3.5),
            ("2025-01-18", "Birikim", "Cumhuriyet Altın", "ALTIN", "BABAM", true, "+", 20200, 2),
            ("2024-08-15", "Birikim", "Çeyrek Altın", "ALTIN", "Evde", true, "+", 5500, 1),
            ("2024-12-01", "Birikim", "ALTIN GRAM", "ALTIN", "Evde", true, "+", 3200, 10),
            // Birikim - COIN
            ("2024-01-15", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 1250000, 0.01),
            ("2024-02-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 1400000, 0.005),
            ("2024-03-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 1900000, 0.003),
            ("2024-03-15", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "-", 2100000, 0.002),
            ("2024-04-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 2000000, 0.002),
            ("2024-05-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 2100000, 0.001),
            ("2024-06-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 2200000, 0.002),
            ("2024-07-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "-", 1950000, 0.003),
            ("2024-08-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 1800000, 0.002),
            ("2024-09-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 1950000, 0.001),
            ("2024-10-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 2300000, 0.001),
            ("2024-11-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 2500000, 0.002),
            ("2024-12-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 2900000, 0.001),
            ("2025-01-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 3100000, 0.001),
            ("2025-02-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "-", 3200000, 0.002),
            ("2025-03-01", "Birikim", "BITCOIN/TRY", "COIN", "BINANCETR", true, "+", 3000000, 0.001),
            ("2024-06-15", "Birikim", "ETH/TRY", "COIN", "BINANCETR", true, "+", 68000, 0.5),
            // Birikim - FON
            ("2024-01-01", "Birikim", "YFBL1", "FON", "Banka", true, "+", 0.85, 50000),
            ("2024-06-01", "Birikim", "YFBL1", "FON", "Banka", true, "+", 0.92, 30000),
            ("2024-01-01", "Birikim", "YFBL7", "FON", "Banka", true, "+", 2.1, 20000),
            ("2024-09-01", "Birikim", "YFBL7", "FON", "Banka", true, "+", 2.3, 10000),
            ("2024-04-01", "Birikim", "YFBA1", "FON", "Banka", true, "+", 0.45, 40000),
            // Birikim - BES
            ("2024-01-01", "Birikim", "BES", "BES", "Banka", true, "+", 31689, 1),
            // Birikim - Maaş
            ("2024-12-01", "Birikim", "Yatırılan Maaş", "Maaş", "Banka", false, "+", 11353.44, 1),
            // Emeklilik
            ("2024-01-01", "Emeklilik", "ALTIN GRAM", "ALTIN", "Evde", true, "+", 1900, 30),
            ("2024-06-01", "Emeklilik", "Cumhuriyet Altın", "ALTIN", "Evde", true, "+", 16000, 3),
            ("2024-10-01", "Emeklilik", "Cumhuriyet Altın", "ALTIN", "BABAM", true, "+", 18500, 5),
            ("2024-12-01", "Emeklilik", "ALTIN GRAM", "ALTIN", "Evde", true, "+", 3200, 10),
            ("2024-01-01", "Emeklilik", "Yatırılan Maaş", "Maaş", "Banka", true, "+", 95000, 1),
            ("2024-06-01", "Emeklilik", "Yatırılan Maaş", "Maaş", "Banka", true, "+", 52000, 1),
            ("2024-12-01", "Emeklilik", "Yatırılan Maaş", "Maaş", "Banka", true, "+", 55595.09, 1),
            ("2024-03-01", "Emeklilik", "YKB Promosyon", "Promosyon", "Banka", false, "+", 10000, 1),
            ("2024-09-01", "Emeklilik", "YKB Promosyon", "Promosyon", "Banka", false, "+", 11500, 1),
            ("2024-06-01", "Emeklilik", "Vadeli", "EmeklilikVadesiz", "Banka", false, "+", 2000, 1),
            ("2024-12-01", "Emeklilik", "Banka", "EmeklilikVadesiz", "Banka", false, "+", 2074.95, 1),
            ("2025-04-04", "Emeklilik", "TUPRS", "HİSSE", "Banka", true, "+", 134.7, 680),
            ("2025-04-04", "Emeklilik", "TUPRS", "HİSSE", "Banka", true, "+", 134.7, 40),
            // Prim
            ("2024-06-01", "Prim", "YFAI1", "FON", "Banka", true, "+", 10.5, 18000),
            ("2024-12-01", "Prim", "YFAE2", "FON", "Banka", true, "+", 0.58, 250000),
            ("2024-03-01", "Prim", "Vadeli", "VADELİ", "Banka", true, "+", 64877, 1),
            // Maaş
            ("2024-09-01", "Maaş", "YFBL1", "FON", "Banka", true, "+", 0.95, 125000),
            // ArabaParası - KCHOL
            ("2025-04-04", "ArabaParası", "KCHOL", "HİSSE", "Banka", true, "+", 161.4, 240),
        ]

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        var count = 0
        for d in data {
            guard let date = df.date(from: d.tarih),
                  let kasaTip = KasaTip(rawValue: d.kasaTip),
                  let birimTip = BirimTip(rawValue: d.tip),
                  let saklamaYeri = SaklamaYeri(rawValue: d.nerede),
                  let yon = HareketYon(rawValue: d.yon) else { continue }

            let tx = Transaction(
                tarih: date,
                kasaTip: kasaTip,
                islem: d.islem,
                tip: birimTip,
                nerede: saklamaYeri,
                guncellenecekMi: d.guncelle,
                yon: yon,
                birimFiyat: d.birimFiyat,
                adet: d.adet
            )
            context.insert(tx)
            count += 1
        }
        return count
    }

    func importDividends() throws -> Int {
        let data: [(tarih: String, hisse: String, adet: Double, birimTemettu: Double)] = [
            ("2024-03-28", "AKBNK", 10, 17.26),
            ("2024-04-05", "TUPRS", 932, 9.34),
            ("2024-04-26", "KCHOL", 200, 7.2),
            ("2024-09-27", "TUPRS", 7200, 10.733),
            ("2025-04-03", "TUPRS", 7880, 6.610256),
            ("2025-04-14", "KCHOL", 940, 5.63899),
        ]

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        var count = 0
        for d in data {
            guard let date = df.date(from: d.tarih) else { continue }
            let div = Dividend(tarih: date, hisse: d.hisse, adet: d.adet, birimTemettu: d.birimTemettu)
            context.insert(div)
            count += 1
        }
        return count
    }

    func importDebts() throws -> Int {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        // Cumhuriyet Altın borç - geri alındı
        let debt1 = Debt(
            kpiAdi: "Baba",
            tip: BorcTipi.cumhuriyetAltin.rawValue,
            miktar: 10,
            birimTutar: 28785,
            verilenTarih: df.date(from: "2025-04-14")!
        )
        // Geri ödeme kaydı ekle
        let payment1 = DebtPayment(tarih: df.date(from: "2026-03-01")!, miktar: 10, birimTutar: 45663)
        payment1.debt = debt1
        debt1.odemeler.append(payment1)
        debt1.durum = BorcDurum.tamamlandi.rawValue
        context.insert(debt1)
        context.insert(payment1)

        // Gram altın borç - bekliyor
        let debt2 = Debt(
            kpiAdi: "Baba",
            tip: BorcTipi.gramAltin.rawValue,
            miktar: 93,
            birimTutar: 4074.03,
            verilenTarih: df.date(from: "2025-04-14")!
        )
        context.insert(debt2)

        return 2
    }

    func importChildExpenses() throws -> Int {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let data: [(yil: Int, kisi: String, aciklama: String, tarih: String, tutarTL: Double, eurDegeri: Double, kategori: String)] = [
            (2019, "ATABERK", "Acıbadem Üniversitesi", "2020-01-29", 17432, 2665, "Eğitim"),
            (2020, "ATABERK", "Acıbadem Üniversitesi", "2020-09-15", 5250, 590, "Eğitim"),
            (2020, "ATABERK", "Acıbadem Üniversitesi", "2021-02-21", 4938, 495, "Eğitim"),
            (2021, "ATABERK", "Acıbadem Üniversitesi", "2021-09-15", 5895, 591, "Eğitim"),
            (2021, "ATABERK", "Acıbadem Üniversitesi", "2022-03-03", 5895, 377, "Eğitim"),
            (2022, "NAZLI İREM", "Bilgenç Kurs ücreti", "2022-06-23", 5000, 273, "Kurs"),
            (2022, "NAZLI İREM", "Aksa Koleji + Yemek + Servis", "2022-09-29", 39000, 2106, "Eğitim"),
            (2022, "NAZLI İREM", "Kıyafet + Yayın Kitap", "2022-09-29", 6000, 323, "Giyim"),
            (2022, "ATABERK", "İRLANDA kursa yatırılan ilk tutar", "2022-11-28", 140744, 7300, "Kurs"),
            (2023, "ATABERK", "VİZE ÜCRETİ", "2022-12-29", 2285, 115, "Seyahat"),
            (2022, "NAZLI İREM", "ÜMİT HOCA özel ders", "2022-12-31", 1000, 48, "Kurs"),
            (2023, "ATABERK", "İRLANDA SEYAHAT SİGORTASI", "2023-01-31", 794, 38, "Seyahat"),
            (2023, "ATABERK", "İRLANDA UÇAK BİLETİ", "2023-01-31", 5900, 280, "Seyahat"),
            (2023, "ATABERK", "İRLANDA elden verilen para", "2023-02-19", 68420, 3250, "Para Transferi"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-03-13", 4000, 190, "Para Transferi"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-03-16", 5000, 238, "Para Transferi"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-04-02", 1000, 48, "Para Transferi"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-04-11", 8000, 380, "Para Transferi"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-04-19", 0, 2000, "Para Transferi"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-05-03", 2000, 93, "Para Transferi"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-05-11", 8000, 372, "Para Transferi"),
            (2023, "ATABERK", "İrlanda arkadaşında aldığı para", "2023-05-20", 0, 1170, "Para Transferi"),
            (2023, "NAZLI İREM", "ÜMİT HOCA özel ders", "2023-05-31", 2250, 107, "Kurs"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-06-01", 800, 35, "Para Transferi"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-06-10", 8000, 320, "Para Transferi"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-06-21", 0, 1590, "Para Transferi"),
            (2023, "NAZLI İREM", "GOP Okul 9.sınıf", "2023-07-20", 3900, 136, "Eğitim"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-07-30", 0, 1000, "Para Transferi"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-08-13", 8000, 264, "Para Transferi"),
            (2023, "NAZLI İREM", "GOP Okul 9.sınıf", "2023-08-20", 3900, 136, "Eğitim"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-08-30", 29200, 1000, "Para Transferi"),
            (2023, "NAZLI İREM", "Okul-Kitap-Kıyafet 9.sınıf", "2023-09-06", 7100, 247, "Eğitim"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-09-11", 8000, 278, "Para Transferi"),
            (2023, "ATABERK", "İstanbul'a geldi - elden verildi", "2023-10-07", 29600, 1000, "Para Transferi"),
            (2023, "NAZLI İREM", "GOP Okul 9.sınıf", "2023-10-19", 3900, 159, "Eğitim"),
            (2023, "NAZLI İREM", "GOP Okul 9.sınıf", "2023-11-19", 3900, 124, "Eğitim"),
            (2023, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2023-12-10", 8000, 250, "Para Transferi"),
            (2023, "NAZLI İREM", "GOP Okul 9.sınıf", "2023-12-19", 3900, 122, "Eğitim"),
            (2024, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2024-01-10", 8000, 250, "Para Transferi"),
            (2024, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2024-01-11", 15000, 450, "Para Transferi"),
            (2024, "NAZLI İREM", "GOP Okul 9.sınıf", "2024-01-19", 3900, 119, "Eğitim"),
            (2024, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2024-02-10", 8000, 250, "Para Transferi"),
            (2024, "NAZLI İREM", "GOP Okul 9.sınıf", "2024-02-19", 3900, 117, "Eğitim"),
            (2024, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2024-03-14", 8000, 250, "Para Transferi"),
            (2024, "ATABERK", "İRLANDA - Uçak bileti", "2024-03-25", 12000, 340, "Seyahat"),
            (2024, "NAZLI İREM", "GOP Okul 10.sınıf kitap-kıyafet ücreti", "2024-03-31", 10000, 287, "Eğitim"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 19 ders ücreti", "2024-04-13", 13300, 385, "Müzik"),
            (2024, "NAZLI İREM", "Anfi ücreti - İngiltere'den getirtildi", "2024-04-06", 6500, 188, "Ekipman"),
            (2024, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2024-04-16", 8000, 231, "Para Transferi"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 2 ders ücreti", "2024-04-18", 1400, 40, "Müzik"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 2 ders ücreti", "2024-04-25", 1400, 40, "Müzik"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 2 ders ücreti", "2024-05-02", 1400, 40, "Müzik"),
            (2024, "NAZLI İREM", "GOP Okul 9.sınıf - 9. ve 10. taksit", "2024-05-03", 7800, 224, "Eğitim"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 2 ders ücreti", "2024-05-09", 1400, 40, "Müzik"),
            (2024, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2024-05-10", 8000, 230, "Para Transferi"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 2 ders ücreti", "2024-05-16", 1400, 40, "Müzik"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 1 ders ücreti", "2024-06-07", 700, 20, "Müzik"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 1 ders ücreti", "2024-06-11", 700, 20, "Müzik"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 1 ders ücreti", "2024-06-13", 700, 20, "Müzik"),
            (2024, "ATABERK", "İRLANDA - PARA TRANSFERİ", "2024-06-18", 8000, 228, "Para Transferi"),
            (2024, "NAZLI İREM", "GOP Okul 9.sınıf - 11. ve 12. taksit", "2024-06-25", 8000, 228, "Eğitim"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 1 ders ücreti", "2024-07-03", 700, 19, "Müzik"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 1 ders ücreti", "2024-07-06", 700, 19, "Müzik"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 1 ders ücreti", "2024-07-10", 700, 19, "Müzik"),
            (2024, "NAZLI İREM", "Müzik Gitar Dersi 1 ders ücreti", "2024-07-13", 700, 19, "Müzik"),
            (2024, "ATABERK", "İRLANDA - PARA TRANSFERİ - Masraflar", "2024-07-31", 15000, 416, "Para Transferi"),
        ]

        var count = 0
        for d in data {
            guard let date = df.date(from: d.tarih) else { continue }
            let expense = ChildExpense(
                yil: d.yil,
                tarih: date,
                cocukAdi: d.kisi,
                kategori: d.kategori,
                aciklama: d.aciklama,
                tutar: d.tutarTL,
                eurDegeri: Double(d.eurDegeri)
            )
            context.insert(expense)
            count += 1
        }
        return count
    }

    func importExchangeRates() throws -> Int {
        // Import a few key exchange rate snapshots
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let ratesData: [(tarih: String, altinGram: Double?, euro: Double?, usd: Double?, ceyrekAltin: Double?, cumhuriyetAltin: Double?, yarimAltin: Double?, kchol: Double?, tuprs: Double?, thyao: Double?, alfas: Double?, arclk: Double?, akbnk: Double?, btc: Double?, eth: Double?)] = [
            ("2024-01-01", nil, 32.63, 29.49, nil, nil, nil, 129.7, 70.26, nil, nil, nil, nil, nil, nil),
            ("2024-06-01", 2500, 35.5, 32.1, 5500, 16000, 10500, 145.0, 120.0, 290.0, 55.0, 115.0, nil, 2200000, 68000),
            ("2024-09-12", 2783.08, 37.40, 33.96, nil, nil, nil, nil, 155.6, nil, nil, nil, nil, nil, nil),
            ("2024-12-09", 3200, 39.5, 35.2, 6200, 24000, 12500, 140.0, 131.3, 295.0, 52.0, 120.0, nil, 2900000, 65000),
            ("2025-02-22", 4074.03, 43.91, 38.20, 7003.87, 28785, 14007.75, 150.6, 125.6, 309.25, 57.55, 124.6, nil, 3580766, nil),
            ("2025-04-04", 4074.03, 43.91, 38.20, 7003.87, 28785, 14007.75, 161.6, 134.6, 305.75, 49.86, 131.7, 51.85, 3129594, 67509),
        ]

        var count = 0
        for d in ratesData {
            guard let date = df.date(from: d.tarih) else { continue }
            let rate = ExchangeRate(tarih: date)
            rate.altinGram = d.altinGram
            rate.euro = d.euro
            rate.usd = d.usd
            rate.ceyrekAltin = d.ceyrekAltin
            rate.cumhuriyetAltin = d.cumhuriyetAltin
            rate.yarimAltin = d.yarimAltin
            rate.kchol = d.kchol
            rate.tuprs = d.tuprs
            rate.thyao = d.thyao
            rate.alfas = d.alfas
            rate.arclk = d.arclk
            rate.akbnk = d.akbnk
            rate.bitcoinTRY = d.btc
            rate.ethTRY = d.eth
            context.insert(rate)
            count += 1
        }
        return count
    }
}
