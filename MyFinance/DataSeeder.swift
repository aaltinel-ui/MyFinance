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
        ]

        // Fetch all ATABERK expenses once, filter in Swift (avoids Double predicate issues)
        let descriptor = FetchDescriptor<ChildExpense>(
            predicate: #Predicate { $0.cocukAdi == "ATABERK" }
        )
        let existing = (try? context.fetch(descriptor)) ?? []

        var didInsert = false
        for entry in entries {
            let alreadyExists = existing.contains {
                abs($0.tutar - entry.tutar) < 0.01 &&
                Calendar.current.isDate($0.tarih, inSameDayAs: entry.tarih)
            }
            guard !alreadyExists else { continue }

            let expense = ChildExpense(
                yil: Calendar.current.component(.year, from: entry.tarih),
                tarih: entry.tarih,
                cocukAdi: entry.cocukAdi,
                kategori: entry.kategori,
                aciklama: entry.aciklama,
                tutar: entry.tutar
            )
            context.insert(expense)
            didInsert = true
        }

        if didInsert {
            try? context.save()
        }
    }
}
