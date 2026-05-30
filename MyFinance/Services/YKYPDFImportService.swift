import Foundation
import PDFKit
import SwiftData

// MARK: - Yapı Kredi Yatırım PDF İçe Aktarma Servisi
//
// Yapı Kredi'nin "HİSSE SENEDİ İŞLEMLERİ" formatındaki PDF raporunu okur.
// Her satırdaki işlem: Tarih | Valör | Pay Senedi | Kod/Ad | Borsa |
//                       Alış/Satış | Adet | Fiyat | Tutar(BSMV) | Komisyon
//
// Kullanım:
//   let rows = YKYPDFImportService.parse(url: pdfURL)
//   let count = YKYPDFImportService.importTransactions(rows, kasaTip:, nerede:, context:)

final class YKYPDFImportService {

    // MARK: - Parsed Row

    struct ParsedRow: Identifiable {
        let id = UUID()
        let tarih: Date
        let hisseKodu: String
        let yon: HareketYon   // .alindi = alış, .satildi = satış
        let adet: Double
        let birimFiyat: Double
        let tutarTL: Double   // BSMV dahil toplam (PDF'teki 3. sayı)

        var yonEtiketi: String { yon == .alindi ? "Alış" : "Satış" }
    }

    // MARK: - Parse PDF

    /// PDF dosyasındaki hisse işlemlerini ayrıştırır.
    static func parse(url: URL) -> [ParsedRow] {
        guard let pdf = PDFDocument(url: url) else { return [] }

        var fullText = ""
        for i in 0..<pdf.pageCount {
            fullText += (pdf.page(at: i)?.string ?? "") + "\n"
        }
        return parseRows(from: fullText)
    }

    // MARK: - Row Parser

    private static func parseRows(from text: String) -> [ParsedRow] {
        var results: [ParsedRow] = []

        // Her satırı incele; "Pay Senedi" içerenler işlem satırıdır.
        let lines = text.components(separatedBy: CharacterSet.newlines)
        for line in lines {
            if let row = parseTransactionLine(line) {
                results.append(row)
            }
        }
        return results
    }

    private static func parseTransactionLine(_ line: String) -> ParsedRow? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // İşlem satırı "Pay Senedi" ile başlar (büyük/küçük harf)
        guard trimmed.lowercased().contains("pay senedi") else { return nil }

        // 1) Tarih: ilk dd/MM/yyyy deseni
        guard let tarih = extractFirstDate(from: trimmed) else { return nil }

        // 2) Hisse kodu: "Pay Senedi " sonrasındaki ilk büyük harf bloğu
        guard let hisseKodu = extractStockCode(from: trimmed) else { return nil }

        // 3) Yön: "ALIŞ" → alındı, "SATIŞ" → satıldı
        let yon = extractYon(from: trimmed)

        // 4) Satır sonundaki sayılar: adet | fiyat | tutar | komisyon
        let numbers = extractTrailingNumbers(from: trimmed)
        // En az 3 sayı: adet, fiyat, tutar (komisyon opsiyonel)
        guard numbers.count >= 3 else { return nil }

        let adet       = numbers[numbers.count - (numbers.count >= 4 ? 4 : 3)]
        let birimFiyat = numbers[numbers.count - (numbers.count >= 4 ? 3 : 2)]
        let tutarTL    = numbers[numbers.count - (numbers.count >= 4 ? 2 : 1)]

        return ParsedRow(
            tarih: tarih,
            hisseKodu: hisseKodu,
            yon: yon,
            adet: adet,
            birimFiyat: birimFiyat,
            tutarTL: tutarTL
        )
    }

    // MARK: - Helpers

    private static func extractFirstDate(from text: String) -> Date? {
        let pattern = #"(\d{2}/\d{2}/\d{4})"#
        guard
            let regex  = try? NSRegularExpression(pattern: pattern),
            let match  = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
            let range  = Range(match.range(at: 1), in: text)
        else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.date(from: String(text[range]))
    }

    private static func extractStockCode(from text: String) -> String? {
        // "Pay Senedi" sonrasındaki ilk büyük harf + rakam kombinasyonu (2-10 karakter)
        let pattern = #"(?i)pay\s+senedi\s+([A-Z0-9]{2,10})\s"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
            let range = Range(match.range(at: 1), in: text)
        else { return nil }
        return String(text[range])
    }

    private static func extractYon(from text: String) -> HareketYon {
        // "SATIŞ" veya "SATIS" içeriyorsa satış, aksi hâlde alış
        let upper = text.uppercased()
        let isSatis = upper.contains("SATI\u{15E}") || // Ş
                      upper.contains("SATI\u{53}")  || // S (ASCII fallback)
                      upper.contains("SATIŞ")       ||
                      upper.contains("SATIS")
        return isSatis ? .satildi : .alindi
    }

    /// Satır sonundaki ardışık Türkçe-formatlı sayıları toplar.
    /// Türk formatı: "." binlik ayraç, "," ondalık ayraç
    /// Örnek: "608,000 88,40 53.747,20 112,30" → [608.0, 88.4, 53747.2, 112.3]
    private static func extractTrailingNumbers(from text: String) -> [Double] {
        let tokens = text.components(separatedBy: .whitespaces)
        var numbers: [Double] = []

        for token in tokens.reversed() {
            guard isTurkishNumber(token), let value = parseTurkishNumber(token) else { break }
            numbers.insert(value, at: 0)
        }
        return numbers
    }

    private static func isTurkishNumber(_ s: String) -> Bool {
        // Sadece rakam, nokta ve virgül; rakamla başlamalı
        guard !s.isEmpty, s.first?.isNumber == true else { return false }
        return s.allSatisfy { $0.isNumber || $0 == "." || $0 == "," }
    }

    static func parseTurkishNumber(_ s: String) -> Double? {
        // "53.747,20" → "5374720" → replace "," → "53747.20"
        let cleaned = s
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }

    // MARK: - SwiftData'ya Aktar

    /// Seçili satırları Transaction olarak SwiftData'ya ekler.
    /// Aynı gün / aynı kod / aynı yon / aynı adet / aynı fiyat kombinasyonu varsa atlar.
    @discardableResult
    static func importRows(
        _ rows: [ParsedRow],
        kasaTip: KasaTip,
        nerede: SaklamaYeri,
        context: ModelContext
    ) -> Int {
        let existing = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        var added = 0

        for row in rows {
            let duplicate = existing.contains { tx in
                tx.islem == row.hisseKodu &&
                tx.yonEnum == row.yon &&
                abs(tx.adet - row.adet) < 0.001 &&
                abs(tx.birimFiyat - row.birimFiyat) < 0.001 &&
                Calendar.current.isDate(tx.tarih, inSameDayAs: row.tarih)
            }
            guard !duplicate else { continue }

            let t = Transaction(
                tarih: row.tarih,
                kasaTip: kasaTip,
                islem: row.hisseKodu,
                tip: .hisse,
                nerede: nerede,
                guncellenecekMi: row.yon == .alindi,
                yon: row.yon,
                birimFiyat: row.birimFiyat,
                adet: row.adet
            )
            // PDF'teki BSMV dahil tutarı override et
            t.tutarTL = row.tutarTL
            // rawValue string'lerini de yaz (enum dışı değerlere karşı tutarlılık)
            t.kasaTip = kasaTip.rawValue
            t.tip = BirimTip.hisse.rawValue
            t.nerede = nerede.rawValue
            t.yon = row.yon.rawValue

            context.insert(t)
            added += 1
        }
        try? context.save()
        return added
    }
}
