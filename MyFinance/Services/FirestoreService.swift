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

    // MARK: - Helpers
    // Firestore tam sayıları Int64, ondalıklıları Double döndürebilir.
    // NSNumber üzerinden cast ederek her iki durumu güvenle handle ederiz.
    private func dbl(_ dict: [String: Any], _ key: String) -> Double {
        (dict[key] as? NSNumber)?.doubleValue ?? 0
    }

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

    // MARK: - Download All

    @MainActor
    func downloadAll(context: ModelContext) async throws -> String {
        var log = ""
        let tx  = try await downloadTransactions(context: context)
        log += "İşlem: \(tx)\n"
        let div = try await downloadDividends(context: context)
        log += "Temettü: \(div)\n"
        let ch  = try await downloadChildExpenses(context: context)
        log += "Çocuk: \(ch)\n"
        let db  = try await downloadDebts(context: context)
        log += "Borç: \(db)\n"
        let ex  = try await downloadExchangeRates(context: context)
        log += "Kur: \(ex)\n"
        let fz  = try await downloadFitreZekat(context: context)
        log += "Fitre/Zekât: \(fz)\n"
        // downloadAll içi doğrulama
        let finalTx = (try? context.fetch(FetchDescriptor<Transaction>()))?.count ?? -1
        let finalEx = (try? context.fetch(FetchDescriptor<ExchangeRate>()))?.count ?? -1
        log += "🔍 fn-içi: \(finalTx) tx, \(finalEx) ex"
        return log
    }

    // MARK: - Download Transactions
    // Not: kasaTip/tip/nerede/yon stringleri kullanıcıya özgü olabilir (enum dışı).
    // Guard yerine fallback kullanılır, asıl string değer sonradan atanır.
    @discardableResult
    @MainActor
    private func downloadTransactions(context: ModelContext) async throws -> String {
        let snapshot = try await db.collection("transactions").getDocuments()
        let total = snapshot.documents.count
        let existing = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        let existingIDs = Set(existing.map { $0.id.uuidString })
        var added = 0

        for doc in snapshot.documents {
            let d = doc.data()
            guard let idStr = d["id"] as? String, !existingIDs.contains(idStr) else { continue }

            let tarih       = (d["tarih"] as? Timestamp)?.dateValue() ?? Date()
            let kasaTipStr  = d["kasaTip"] as? String ?? ""
            let tipStr      = d["tip"] as? String ?? ""
            let neredeStr   = d["nerede"] as? String ?? ""
            let yonStr      = d["yon"] as? String ?? ""

            let kasaTip = KasaTip(rawValue: kasaTipStr) ?? .birikim
            let tip     = BirimTip(rawValue: tipStr) ?? .hisse
            let nerede  = SaklamaYeri(rawValue: neredeStr) ?? .banka
            let yon     = HareketYon(rawValue: yonStr) ?? .arti

            let t = Transaction(
                tarih: tarih, kasaTip: kasaTip,
                islem: d["islem"] as? String ?? "",
                tip: tip, nerede: nerede,
                guncellenecekMi: d["guncellenecekMi"] as? Bool ?? true,
                yon: yon,
                birimFiyat: dbl(d, "birimFiyat"),
                adet: dbl(d, "adet"),
                notlar: d["notlar"] as? String
            )
            t.kasaTip = kasaTipStr; t.tip = tipStr; t.nerede = neredeStr; t.yon = yonStr
            // tutarTL'yi Firestore'dan gelen değerle override et (birimFiyat*adet'ten farklı olabilir)
            let tutarTL = dbl(d, "tutarTL")
            if tutarTL > 0 { t.tutarTL = tutarTL }
            if let uuid = UUID(uuidString: idStr) { t.id = uuid }
            context.insert(t)
            added += 1
        }
        // Save öncesi: context'teki pending insert sayısı
        let beforeSave = context.insertedModelsArray.count
        do {
            try context.save()
        } catch {
            return "\(added) yeni / \(total) toplam [SAVE HATA: \(error)]"
        }
        // Save sonrası: persistent store'daki kayıt sayısı
        let afterSave = (try? context.fetch(FetchDescriptor<Transaction>()))?.count ?? -1
        return "\(added) yeni / \(total) toplam [pending:\(beforeSave) after:\(afterSave)]"
    }

    // MARK: - Download Dividends

    @discardableResult
    @MainActor
    private func downloadDividends(context: ModelContext) async throws -> String {
        let snapshot = try await db.collection("dividends").getDocuments()
        let total = snapshot.documents.count
        let existing = (try? context.fetch(FetchDescriptor<Dividend>())) ?? []
        let existingIDs = Set(existing.map { $0.id.uuidString })
        var added = 0

        for doc in snapshot.documents {
            let d = doc.data()
            guard let idStr = d["id"] as? String, !existingIDs.contains(idStr) else { continue }
            let tarih = (d["tarih"] as? Timestamp)?.dateValue() ?? Date()
            let div = Dividend(tarih: tarih, hisse: d["hisse"] as? String ?? "",
                               adet: dbl(d, "adet"),
                               birimTemettu: dbl(d, "birimTemettu"))
            if let uuid = UUID(uuidString: idStr) { div.id = uuid }
            context.insert(div); added += 1
        }
        try context.save()
        return "\(added) yeni / \(total) toplam"
    }

    // MARK: - Download Child Expenses

    @discardableResult
    @MainActor
    private func downloadChildExpenses(context: ModelContext) async throws -> String {
        let snapshot = try await db.collection("childExpenses").getDocuments()
        let total = snapshot.documents.count
        let existing = (try? context.fetch(FetchDescriptor<ChildExpense>())) ?? []
        let existingIDs = Set(existing.map { $0.id.uuidString })
        var added = 0

        for doc in snapshot.documents {
            let d = doc.data()
            guard let idStr = d["id"] as? String, !existingIDs.contains(idStr) else { continue }
            let tarih = (d["tarih"] as? Timestamp)?.dateValue() ?? Date()
            let yil   = (d["yil"] as? NSNumber)?.intValue ?? Calendar.current.component(.year, from: tarih)
            let exp = ChildExpense(yil: yil, tarih: tarih,
                cocukAdi: d["cocukAdi"] as? String ?? "", kategori: d["kategori"] as? String ?? "",
                aciklama: d["aciklama"] as? String ?? "", tutar: dbl(d, "tutar"),
                eurDegeri: dbl(d, "eurDegeri"), kur: dbl(d, "kur"),
                notlar: d["notlar"] as? String)
            if let uuid = UUID(uuidString: idStr) { exp.id = uuid }
            context.insert(exp); added += 1
        }
        try context.save()
        return "\(added) yeni / \(total) toplam"
    }

    // MARK: - Download Debts

    @discardableResult
    @MainActor
    private func downloadDebts(context: ModelContext) async throws -> String {
        let snapshot = try await db.collection("debts").getDocuments()
        let total = snapshot.documents.count
        let existing = (try? context.fetch(FetchDescriptor<Debt>())) ?? []
        let existingIDs = Set(existing.map { $0.id.uuidString })
        var added = 0

        for doc in snapshot.documents {
            let d = doc.data()
            guard let idStr = d["id"] as? String, !existingIDs.contains(idStr) else { continue }
            let debt = Debt(
                kpiAdi: d["kpiAdi"] as? String ?? "", tip: d["tip"] as? String ?? "",
                miktar: dbl(d, "miktar"), birimTutar: dbl(d, "birimTutar"),
                paraBirimi: d["paraBirimi"] as? String ?? "TL",
                verilenTarih: (d["verilenTarih"] as? Timestamp)?.dateValue() ?? Date(),
                notlar: d["notlar"] as? String)
            debt.durum = d["durum"] as? String ?? BorcDurum.acik.rawValue
            if let uuid = UUID(uuidString: idStr) { debt.id = uuid }
            if let odemelerData = d["odemeler"] as? [[String: Any]] {
                for pd in odemelerData {
                    let odeme = DebtPayment(
                        tarih: (pd["tarih"] as? Timestamp)?.dateValue() ?? Date(),
                        miktar: dbl(pd, "miktar"),
                        birimTutar: dbl(pd, "birimTutar"),
                        notlar: pd["notlar"] as? String)
                    if let pIdStr = pd["id"] as? String, let uuid = UUID(uuidString: pIdStr) { odeme.id = uuid }
                    debt.odemeler.append(odeme)
                }
            }
            context.insert(debt); added += 1
        }
        try context.save()
        return "\(added) yeni / \(total) toplam"
    }

    // MARK: - Download Exchange Rates

    @discardableResult
    @MainActor
    private func downloadExchangeRates(context: ModelContext) async throws -> String {
        let snapshot = try await db.collection("exchangeRates").getDocuments()
        let total = snapshot.documents.count
        let existing = (try? context.fetch(FetchDescriptor<ExchangeRate>())) ?? []
        let existingIDs = Set(existing.map { $0.id.uuidString })
        var added = 0

        for doc in snapshot.documents {
            let d = doc.data()
            guard let idStr = d["id"] as? String, !existingIDs.contains(idStr) else { continue }
            let tarih = (d["tarih"] as? Timestamp)?.dateValue() ?? Date()
            let rate = ExchangeRate(tarih: tarih)
            if let uuid = UUID(uuidString: idStr) { rate.id = uuid }
            let optDbl: (String) -> Double? = { (d[$0] as? NSNumber).map { $0.doubleValue } }
            rate.altinGram       = optDbl("altinGram")
            rate.euro            = optDbl("euro")
            rate.usd             = optDbl("usd")
            rate.ceyrekAltin     = optDbl("ceyrekAltin")
            rate.cumhuriyetAltin = optDbl("cumhuriyetAltin")
            rate.yarimAltin      = optDbl("yarimAltin")
            rate.kchol           = optDbl("kchol")
            rate.tuprs           = optDbl("tuprs")
            rate.thyao           = optDbl("thyao")
            rate.alfas           = optDbl("alfas")
            rate.arclk           = optDbl("arclk")
            rate.akbnk           = optDbl("akbnk")
            rate.yfbl1           = optDbl("yfbl1")
            rate.yfbl7           = optDbl("yfbl7")
            rate.yfba1           = optDbl("yfba1")
            rate.yfai1           = optDbl("yfai1")
            rate.yfae2           = optDbl("yfae2")
            rate.bitcoinTRY      = optDbl("bitcoinTRY")
            rate.ethTRY          = optDbl("ethTRY")
            context.insert(rate); added += 1
        }
        try context.save()
        return "\(added) yeni / \(total) toplam"
    }

    // MARK: - Download Fitre & Zekat

    @discardableResult
    @MainActor
    private func downloadFitreZekat(context: ModelContext) async throws -> String {
        let snapshot = try await db.collection("fitreZekat").getDocuments()
        let total = snapshot.documents.count
        let existing = (try? context.fetch(FetchDescriptor<FitreZekat>())) ?? []
        let existingIDs = Set(existing.map { $0.id.uuidString })
        var added = 0

        for doc in snapshot.documents {
            let d = doc.data()
            guard let idStr = d["id"] as? String, !existingIDs.contains(idStr) else { continue }
            let fz = FitreZekat(
                tarih:    (d["tarih"] as? Timestamp)?.dateValue() ?? Date(),
                tur:      d["tur"] as? String ?? "",
                kisiAdi:  d["kisiAdi"] as? String ?? "",
                tutar:    dbl(d, "tutar"),
                aciklama: d["aciklama"] as? String ?? "",
                notlar:   d["notlar"] as? String)
            if let uuid = UUID(uuidString: idStr) { fz.id = uuid }
            context.insert(fz); added += 1
        }
        try context.save()
        return "\(added) yeni / \(total) toplam"
    }
}
