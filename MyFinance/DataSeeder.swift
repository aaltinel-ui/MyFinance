import Foundation
import SwiftData

struct DataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let targetDate: Date = {
            var components = DateComponents()
            components.year = 2026
            components.month = 3
            components.day = 15
            return Calendar.current.date(from: components) ?? Date()
        }()

        let startOfDay = Calendar.current.startOfDay(for: targetDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        var descriptor = FetchDescriptor<ChildExpense>(
            predicate: #Predicate {
                $0.cocukAdi == "ATABERK" &&
                $0.tutar == 500 &&
                $0.tarih >= startOfDay &&
                $0.tarih < endOfDay
            }
        )
        descriptor.fetchLimit = 1

        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let expense = ChildExpense(
            yil: 2026,
            tarih: targetDate,
            cocukAdi: "ATABERK",
            kategori: CocukHarcamaKategori.diger.rawValue,
            aciklama: "Harcama",
            tutar: 500
        )
        context.insert(expense)
        try? context.save()
    }
}
