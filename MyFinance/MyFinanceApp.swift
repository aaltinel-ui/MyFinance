//
//  MyFinanceApp.swift
//  MyFinance
//
//  Created by ALPAY's MacBook on 15.03.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct MyFinanceApp: App {
    let container: ModelContainer

    init() {
        FirebaseApp.configure()
        self.container = Self.makeContainer()
        Self.normalizeTransactionTypes(context: container.mainContext)
    }

    /// Yanlış kategorize edilmiş enstrümanların tipini düzeltir (örn. EURO → DÖVİZ,
    /// Gram Gümüş → GÜMÜŞ). İdempotent: her açılışta çalışır, yalnızca değişiklik
    /// varsa kaydeder. Firebase'den gelen kayıtlar da indirme sırasında normalize edilir.
    @MainActor
    private static func normalizeTransactionTypes(context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        var changed = 0
        for tx in all {
            let norm = BirimTip.normalizedTip(islem: tx.islem, tip: tx.tip)
            if norm != tx.tip {
                tx.tip = norm
                changed += 1
            }
        }
        if changed > 0 {
            try? context.save()
            print("🔧 \(changed) işlemin tipi normalize edildi (DÖVİZ/GÜMÜŞ)")
        }
    }

    // Şema versiyonu değiştiğinde SwiftData hash kontrolünü geçemez ve
    // container sessizce boş kalır (insert/fetch sıfır döner).
    // Bir kerelik reset ile eski store silinir; veriler Firebase'de
    // olduğundan bu güvenlidir.  Reset key'ini değiştirerek tekrar
    // tetiklenebilir (örn. storeSchemaResetV2).
    private static let storeResetKey = "storeSchemaResetV1"

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Transaction.self,
            Dividend.self,
            Debt.self,
            DebtPayment.self,
            ExchangeRate.self,
            ChildExpense.self,
            FitreZekat.self,
            BESHesap.self
        ])

        // Bir kerelik: mevcut store'u silerek taze bir başlangıç yap
        if !UserDefaults.standard.bool(forKey: storeResetKey) {
            let appSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first!
            for name in ["default.store", "default.store-shm", "default.store-wal"] {
                let url = appSupport.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.removeItem(at: url)
                    print("🗑️ Eski store silindi: \(name)")
                }
            }
            UserDefaults.standard.set(true, forKey: storeResetKey)
        }

        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
