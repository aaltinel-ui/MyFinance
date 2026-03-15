import Foundation
import SwiftData

struct DataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let seededKey = "ataberkExpenseSeeded"
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

        let expense = ChildExpense(
            yil: 2026,
            tarih: {
                var components = DateComponents()
                components.year = 2026
                components.month = 3
                components.day = 15
                return Calendar.current.date(from: components) ?? Date()
            }(),
            cocukAdi: "ATABERK",
            kategori: CocukHarcamaKategori.diger.rawValue,
            aciklama: "Harcama",
            tutar: 500
        )
        context.insert(expense)
        try? context.save()

        UserDefaults.standard.set(true, forKey: seededKey)
    }
}
