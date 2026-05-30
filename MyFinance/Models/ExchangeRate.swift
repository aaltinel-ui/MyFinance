import Foundation
import SwiftData

@Model
final class ExchangeRate {
    var id: UUID
    var tarih: Date
    var altinGram: Double?
    var euro: Double?
    var usd: Double?
    var ceyrekAltin: Double?
    var cumhuriyetAltin: Double?
    var yarimAltin: Double?
    var kchol: Double?
    var tuprs: Double?
    var thyao: Double?
    var alfas: Double?
    var arclk: Double?
    var akbnk: Double?
    var yfbl1: Double?
    var yfbl7: Double?
    var yfba1: Double?
    var yfai1: Double?
    var yfae2: Double?
    var bitcoinTRY: Double?
    var ethTRY: Double?

    init(tarih: Date) {
        self.id = UUID()
        self.tarih = tarih
    }

    func price(for instrument: String) -> Double? {
        switch instrument {
        case "ALTIN GRAM", "24 Ayar Gram Altın", "Gram Altın": return altinGram
        case "Euro", "EURO", "EUR": return euro
        case "Usd", "USD", "Dolar", "DOLAR": return usd
        case "Çeyrek Altın": return ceyrekAltin
        case "Cumhuriyet Altın": return cumhuriyetAltin
        case "Yarım Altın": return yarimAltin
        case "KCHOL": return kchol
        case "TUPRS": return tuprs
        case "THYAO": return thyao
        case "ALFAS": return alfas
        case "ARCLK": return arclk
        case "AKBNK": return akbnk
        case "YFBL1": return yfbl1
        case "YFBL7": return yfbl7
        case "YFBA1": return yfba1
        case "YFAI1": return yfai1
        case "YFAE2": return yfae2
        case "BITCOIN/TRY": return bitcoinTRY
        case "ETH/TRY": return ethTRY
        default: return nil
        }
    }
}
