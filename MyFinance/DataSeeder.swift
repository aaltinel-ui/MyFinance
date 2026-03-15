import Foundation
import SwiftData

struct DataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let today: Date = {
            var components = DateComponents()
            components.year = 2026
            components.month = 3
            components.day = 15
            return Calendar.current.date(from: components) ?? Date()
        }()

        seedExpenseIfNeeded(
            context: context,
            cocukAdi: "ATABERK",
            tutar: 500,
            kategori: CocukHarcamaKategori.diger.rawValue,
            aciklama: "Harcama",
            tarih: today
        )

        seedExpenseIfNeeded(
            context: context,
            cocukAdi: "ATABERK",
            tutar: 999,
            kategori: CocukHarcamaKategori.egitim.rawValue,
            aciklama: "Eğitim Harcaması",
            tarih: today
        )
    }

    private static func seedExpenseIfNeeded(
        context: ModelContext,
        cocukAdi: String,
        tutar: Double,
        kategori: String,
        aciklama: String,
        tarih: Date
    ) {
        let startOfDay = Calendar.current.startOfDay(for: tarih)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        var descriptor = FetchDescriptor<ChildExpense>(
            predicate: #Predicate {
                $0.cocukAdi == cocukAdi &&
                $0.tutar == tutar &&
                $0.tarih >= startOfDay &&
                $0.tarih < endOfDay
            }
        )
        descriptor.fetchLimit = 1

        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let expense = ChildExpense(
            yil: Calendar.current.component(.year, from: tarih),
            tarih: tarih,
            cocukAdi: cocukAdi,
            kategori: kategori,
            aciklama: aciklama,
            tutar: tutar
        )
        context.insert(expense)
        try? context.save()
    }
}
