import Foundation
import SwiftData

@Observable
class PortfolioCalculator {
    var positions: [InstrumentPosition] = []
    var typeSummaries: [TypeSummary] = []
    var kasaSummaries: [KasaSummary] = []
    var portfolioSummary = PortfolioSummary()

    func calculate(transactions: [Transaction], latestRates: ExchangeRate?) {
        var positionMap: [String: InstrumentPosition] = []

        for tx in transactions {
            let key = "\(tx.kasaTip)|\(tx.islem)"
            if var pos = positionMap[key] {
                if tx.isPositive {
                    pos.toplamMaliyet += tx.tutarTL
                    pos.toplamAdet += tx.adet
                } else {
                    let ratio = min(tx.adet / pos.toplamAdet, 1.0)
                    pos.toplamMaliyet -= pos.toplamMaliyet * ratio
                    pos.toplamAdet -= tx.adet
                }
                pos.guncelFiyat = latestRates?.price(for: tx.islem) ?? tx.birimFiyat
                positionMap[key] = pos
            } else {
                let guncelFiyat = latestRates?.price(for: tx.islem) ?? tx.birimFiyat
                let pos = InstrumentPosition(
                    islem: tx.islem,
                    tip: tx.tip,
                    kasaTip: tx.kasaTip,
                    toplamAdet: tx.isPositive ? tx.adet : -tx.adet,
                    toplamMaliyet: tx.isPositive ? tx.tutarTL : -tx.tutarTL,
                    guncelFiyat: guncelFiyat
                )
                positionMap[key] = pos
            }
        }

        positions = positionMap.values
            .filter { $0.toplamAdet > 0 }
            .sorted { $0.guncelDeger > $1.guncelDeger }

        // Type summaries
        var typeMap: [String: TypeSummary] = [:]
        for pos in positions {
            if var ts = typeMap[pos.tip] {
                ts.toplamMaliyet += pos.toplamMaliyet
                ts.guncelDeger += pos.guncelDeger
                typeMap[pos.tip] = ts
            } else {
                typeMap[pos.tip] = TypeSummary(
                    tip: pos.tip,
                    toplamMaliyet: pos.toplamMaliyet,
                    guncelDeger: pos.guncelDeger
                )
            }
        }
        typeSummaries = typeMap.values.sorted { $0.guncelDeger > $1.guncelDeger }

        // Kasa summaries
        var kasaMap: [String: (maliyet: Double, deger: Double, positions: [InstrumentPosition])] = [:]
        for pos in positions {
            var entry = kasaMap[pos.kasaTip] ?? (0, 0, [])
            entry.maliyet += pos.toplamMaliyet
            entry.deger += pos.guncelDeger
            entry.positions.append(pos)
            kasaMap[pos.kasaTip] = entry
        }
        kasaSummaries = kasaMap.map { key, val in
            KasaSummary(
                kasaTip: key,
                toplamMaliyet: val.maliyet,
                guncelDeger: val.deger,
                positions: val.positions.sorted { $0.guncelDeger > $1.guncelDeger }
            )
        }.sorted { $0.guncelDeger > $1.guncelDeger }

        // Portfolio summary
        portfolioSummary.toplamMaliyet = positions.reduce(0) { $0 + $1.toplamMaliyet }
        portfolioSummary.toplamDeger = positions.reduce(0) { $0 + $1.guncelDeger }
    }

    func positions(for kasaTip: String? = nil, tip: String? = nil) -> [InstrumentPosition] {
        positions.filter { pos in
            (kasaTip == nil || pos.kasaTip == kasaTip) &&
            (tip == nil || pos.tip == tip)
        }
    }

    func goldPositions(kasaTip: String? = nil) -> [InstrumentPosition] {
        positions(for: kasaTip, tip: BirimTip.altin.rawValue)
    }
}
