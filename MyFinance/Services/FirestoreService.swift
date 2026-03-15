import Foundation
import FirebaseFirestore
import SwiftData

// MARK: - FirestoreService
// Tüm SwiftData modellerini Firestore ile senkronize eder.
// Kullanım: FirestoreService.shared.uploadAll(context: modelContext)

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Upload All

    func uploadAll(context: ModelContext) {
        uploadTransactions(context: context)
        uploadDebts(context: context)
        uploadChildExpenses(context: context)
        uploadDividends(context: context)
        uploadExchangeRates(context: context)
        uploadFitreZekat(context: context)
    }

    // MARK: - Transactions

    func uploadTransactions(context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        let col = db.collection("transactions")
        for item in items {
            let data: [String: Any] = [
                "id": item.id.uuidString,
                "tarih": Timestamp(date: item.tarih),
                "kasaTip": item.kasaTip,
                "islem": item.islem,
                "tip": item.tip,
                "nerede": item.nerede,
                "guncellenecekMi": item.guncellenecekMi,
                "yon": item.yon,
                "birimFiyat": item.birimFiyat,
                "adet": item.adet,
                "tutarTL": item.tutarTL,
                "notlar": item.notlar ?? ""
            ]
            col.document(item.id.uuidString).setData(data, merge: true)
        }
    }

    // MARK: - Debts

    func uploadDebts(context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<Debt>())) ?? []
        let col = db.collection("debts")
        for item in items {
            var data: [String: Any] = [
                "id": item.id.uuidString,
                "kpiAdi": item.kpiAdi,
                "tip": item.tip,
                "miktar": item.miktar,
                "birimTutar": item.birimTutar,
                "toplamTutar": item.toplamTutar,
                "paraBirimi": item.paraBirimi,
                "verilenTarih": Timestamp(date: item.verilenTarih),
                "durum": item.durum,
                "notlar": item.notlar ?? ""
            ]

            // Ödemeler
            let odemeler = item.odemeler.map { p -> [String: Any] in
                [
                    "id": p.id.uuidString,
                    "tarih": Timestamp(date: p.tarih),
                    "miktar": p.miktar,
                    "birimTutar": p.birimTutar,
                    "toplamTutar": p.toplamTutar,
                    "notlar": p.notlar ?? ""
                ]
            }
            data["odemeler"] = odemeler

            col.document(item.id.uuidString).setData(data, merge: true)
        }
    }

    // MARK: - Child Expenses

    func uploadChildExpenses(context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<ChildExpense>())) ?? []
        let col = db.collection("childExpenses")
        for item in items {
            let data: [String: Any] = [
                "id": item.id.uuidString,
                "yil": item.yil,
                "tarih": Timestamp(date: item.tarih),
                "cocukAdi": item.cocukAdi,
                "kategori": item.kategori,
                "aciklama": item.aciklama,
                "tutar": item.tutar,
                "eurDegeri": item.eurDegeri,
                "kur": item.kur,
                "notlar": item.notlar ?? ""
            ]
            col.document(item.id.uuidString).setData(data, merge: true)
        }
    }

    // MARK: - Dividends

    func uploadDividends(context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<Dividend>())) ?? []
        let col = db.collection("dividends")
        for item in items {
            let data: [String: Any] = [
                "id": item.id.uuidString,
                "tarih": Timestamp(date: item.tarih),
                "hisse": item.hisse,
                "adet": item.adet,
                "birimTemettu": item.birimTemettu,
                "toplamTutar": item.toplamTutar,
                "notlar": item.notlar ?? ""
            ]
            col.document(item.id.uuidString).setData(data, merge: true)
        }
    }

    // MARK: - Exchange Rates

    func uploadExchangeRates(context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<ExchangeRate>())) ?? []
        let col = db.collection("exchangeRates")
        for item in items {
            var data: [String: Any] = [
                "id": item.id.uuidString,
                "tarih": Timestamp(date: item.tarih)
            ]
            if let v = item.altinGram      { data["altinGram"] = v }
            if let v = item.euro           { data["euro"] = v }
            if let v = item.usd            { data["usd"] = v }
            if let v = item.ceyrekAltin    { data["ceyrekAltin"] = v }
            if let v = item.cumhuriyetAltin { data["cumhuriyetAltin"] = v }
            if let v = item.yarimAltin     { data["yarimAltin"] = v }
            if let v = item.kchol          { data["kchol"] = v }
            if let v = item.tuprs          { data["tuprs"] = v }
            if let v = item.thyao          { data["thyao"] = v }
            if let v = item.alfas          { data["alfas"] = v }
            if let v = item.arclk          { data["arclk"] = v }
            if let v = item.akbnk          { data["akbnk"] = v }
            if let v = item.yfbl1          { data["yfbl1"] = v }
            if let v = item.yfbl7          { data["yfbl7"] = v }
            if let v = item.yfba1          { data["yfba1"] = v }
            if let v = item.yfai1          { data["yfai1"] = v }
            if let v = item.yfae2          { data["yfae2"] = v }
            if let v = item.bitcoinTRY     { data["bitcoinTRY"] = v }
            if let v = item.ethTRY         { data["ethTRY"] = v }
            col.document(item.id.uuidString).setData(data, merge: true)
        }
    }

    // MARK: - Fitre & Zekat

    func uploadFitreZekat(context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<FitreZekat>())) ?? []
        let col = db.collection("fitreZekat")
        for item in items {
            let data: [String: Any] = [
                "id": item.id.uuidString,
                "tarih": Timestamp(date: item.tarih),
                "tur": item.tur,
                "kisiAdi": item.kisiAdi,
                "tutar": item.tutar,
                "aciklama": item.aciklama,
                "notlar": item.notlar ?? ""
            ]
            col.document(item.id.uuidString).setData(data, merge: true)
        }
    }
}
