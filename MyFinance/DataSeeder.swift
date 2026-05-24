import Foundation
import SwiftData

struct DataSeeder {
    private struct SeedEntry {
        let cocukAdi: String
        let tutar: Double
        let kategori: String
        let aciklama: String
        let tarih: Date
    }

    static func seedIfNeeded(context: ModelContext) {
        let date20260315: Date = {
            var c = DateComponents()
            c.year = 2026; c.month = 3; c.day = 15
            return Calendar.current.date(from: c) ?? Date()
        }()

        let entries: [SeedEntry] = [
            SeedEntry(cocukAdi: "ATABERK", tutar: 500,  kategori: CocukHarcamaKategori.diger.rawValue,  aciklama: "Harcama",          tarih: date20260315),
            SeedEntry(cocukAdi: "ATABERK", tutar: 999,  kategori: CocukHarcamaKategori.egitim.rawValue, aciklama: "Eğitim Harcaması", tarih: date20260315),
            SeedEntry(cocukAdi: "ALPAY",   tutar: 500,  kategori: CocukHarcamaKategori.diger.rawValue,  aciklama: "Harcama",          tarih: date20260315),
        ]

        // Fetch ALL expenses without any predicate to avoid SwiftData predicate issues
        let existing = (try? context.fetch(FetchDescriptor<ChildExpense>())) ?? []

        for entry in entries {
            let alreadyExists = existing.contains {
                $0.cocukAdi == entry.cocukAdi &&
                abs($0.tutar - entry.tutar) < 0.01 &&
                Calendar.current.isDate($0.tarih, inSameDayAs: entry.tarih)
            }
            guard !alreadyExists else { continue }

            context.insert(ChildExpense(
                yil: Calendar.current.component(.year, from: entry.tarih),
                tarih: entry.tarih,
                cocukAdi: entry.cocukAdi,
                kategori: entry.kategori,
                aciklama: entry.aciklama,
                tutar: entry.tutar
            ))
        }

        // Borç seed
        let existingDebts = (try? context.fetch(FetchDescriptor<Debt>())) ?? []
        let debtAlreadyExists = existingDebts.contains {
            $0.kpiAdi == "aaaa" &&
            abs($0.toplamTutar - 888) < 0.01 &&
            Calendar.current.isDate($0.verilenTarih, inSameDayAs: date20260315)
        }
        if !debtAlreadyExists {
            context.insert(Debt(
                kpiAdi: "aaaa",
                tip: "Nakit",
                miktar: 1,
                birimTutar: 888,
                paraBirimi: "TL",
                verilenTarih: date20260315
            ))
        }

        // Transaction seed — FROTO alış 18/05/2026
        let frotoTarih = date(2026, 5, 18)
        let existingTx = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        let frotoAlreadyExists = existingTx.contains {
            $0.islem == "FROTO" &&
            abs($0.adet - 608) < 0.01 &&
            Calendar.current.isDate($0.tarih, inSameDayAs: frotoTarih)
        }
        if !frotoAlreadyExists {
            let tx = Transaction(
                tarih: frotoTarih,
                kasaTip: .birikim,
                islem: "FROTO",
                tip: .hisse,
                nerede: .banka,
                guncellenecekMi: true,
                yon: .alindi,
                birimFiyat: 88.40,
                adet: 608,
                notlar: "Ford Otomotiv Sanayi A.Ş. — Yapı Kredi Yatırım"
            )
            context.insert(tx)
        }

        try? context.save()
    }
}

private extension DataSeeder {
    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        return Calendar.current.date(from: c) ?? Date()
    }
}
