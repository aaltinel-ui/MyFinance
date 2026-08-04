import Foundation

actor PriceService {
    static let shared = PriceService()

    struct CollectAPIResponse: Codable {
        let result: CollectResult?
    }

    struct CollectResult: Codable {
        let data: [CollectData]?
    }

    struct CollectData: Codable {
        let code: String?
        let lastprice: Double?
        let text: String?
    }

    func fetchBISTPrice(symbol: String) async throws -> Double? {
        let urlString = "https://api.collectapi.com/economy/hpiSingle?code=\(symbol)"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // User needs to set their own API key
        if let apiKey = UserDefaults.standard.string(forKey: "collectAPIKey"), !apiKey.isEmpty {
            request.setValue("apikey \(apiKey)", forHTTPHeaderField: "authorization")
        } else {
            return nil
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CollectAPIResponse.self, from: data)
        return response.result?.data?.first?.lastprice
    }

    struct ExchangeRateResponse: Codable {
        let rates: [String: Double]?
    }

    func fetchGoldPrices() async throws -> (gram: Double?, ceyrek: Double?, yarim: Double?, cumhuriyet: Double?) {
        let urlString = "https://api.collectapi.com/economy/goldPrice"
        guard let url = URL(string: urlString) else { return (nil, nil, nil, nil) }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = UserDefaults.standard.string(forKey: "collectAPIKey"), !apiKey.isEmpty {
            request.setValue("apikey \(apiKey)", forHTTPHeaderField: "authorization")
        } else {
            return (nil, nil, nil, nil)
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let result = json?["result"] as? [[String: Any]] else {
            return (nil, nil, nil, nil)
        }

        var gram: Double?
        var ceyrek: Double?
        var yarim: Double?
        var cumhuriyet: Double?

        for item in result {
            let name = item["name"] as? String ?? ""
            let buying = item["buying"] as? Double ?? 0
            if name.contains("Gram") { gram = buying }
            if name.contains("Çeyrek") { ceyrek = buying }
            if name.contains("Yarım") { yarim = buying }
            if name.contains("Cumhuriyet") { cumhuriyet = buying }
        }

        return (gram, ceyrek, yarim, cumhuriyet)
    }

    func fetchCurrencyRates() async throws -> (eur: Double?, usd: Double?) {
        let urlString = "https://api.collectapi.com/economy/allCurrency"
        guard let url = URL(string: urlString) else { return (nil, nil) }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = UserDefaults.standard.string(forKey: "collectAPIKey"), !apiKey.isEmpty {
            request.setValue("apikey \(apiKey)", forHTTPHeaderField: "authorization")
        } else {
            return (nil, nil)
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let result = json?["result"] as? [[String: Any]] else {
            return (nil, nil)
        }

        var eur: Double?
        var usd: Double?

        for item in result {
            let code = item["code"] as? String ?? ""
            let buying = item["buying"] as? Double
            if code == "EUR" { eur = buying }
            if code == "USD" { usd = buying }
        }

        return (eur, usd)
    }

    func fetchCryptoPrices() async throws -> (btc: Double?, eth: Double?) {
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=try"
        guard let url = URL(string: urlString) else { return (nil, nil) }

        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let btc = (json?["bitcoin"] as? [String: Any])?["try"] as? Double
        let eth = (json?["ethereum"] as? [String: Any])?["try"] as? Double

        return (btc, eth)
    }

    /// Tüm fiyatları günceller. `previous` verilirse, canlı kaynaktan çekilemeyen
    /// alanlar (ör. API anahtarı eksikse veya bir istek başarısız olursa) `nil`
    /// ile ezilmez — bir önceki bilinen değer korunur.
    func fetchAllPrices(previous: ExchangeRate? = nil) async -> ExchangeRate {
        let rate = ExchangeRate(tarih: Date())

        async let goldTask = try? fetchGoldPrices()
        async let currencyTask = try? fetchCurrencyRates()
        async let cryptoTask = try? fetchCryptoPrices()

        let gold = await goldTask
        let currency = await currencyTask
        let crypto = await cryptoTask

        rate.altinGram       = gold?.gram       ?? previous?.altinGram
        rate.ceyrekAltin     = gold?.ceyrek     ?? previous?.ceyrekAltin
        rate.yarimAltin      = gold?.yarim      ?? previous?.yarimAltin
        rate.cumhuriyetAltin = gold?.cumhuriyet ?? previous?.cumhuriyetAltin
        rate.euro            = currency?.eur    ?? previous?.euro
        rate.usd             = currency?.usd    ?? previous?.usd
        rate.bitcoinTRY      = crypto?.btc      ?? previous?.bitcoinTRY
        rate.ethTRY          = crypto?.eth      ?? previous?.ethTRY
        // Fon fiyatlarının canlı kaynağı yok — bir önceki bilinen değeri taşı
        rate.yfbl1 = previous?.yfbl1
        rate.yfbl7 = previous?.yfbl7
        rate.yfba1 = previous?.yfba1
        rate.yfai1 = previous?.yfai1
        rate.yfae2 = previous?.yfae2

        // BIST hisseleri — sabit liste değil, kullanıcının Hisse Senedi
        // Kataloğu'ndan (Ayarlar) dinamik olarak okunur, böylece DMLKT gibi
        // sonradan eklenen semboller de canlı fiyat alır.
        let catalog = UserDefaults.standard.stringArray(forKey: "stockKey")
            ?? ["KCHOL", "TUPRS", "THYAO", "ALFAS", "ARCLK", "AKBNK"]

        var extra = previous?.extraStocks ?? [:]
        for stock in catalog {
            let fetched: Double? = try? await fetchBISTPrice(symbol: stock)
            let price = fetched ?? extra[stock]

            switch stock {
            case "KCHOL": rate.kchol = price
            case "TUPRS": rate.tuprs = price
            case "THYAO": rate.thyao = price
            case "ALFAS": rate.alfas = price
            case "ARCLK": rate.arclk = price
            case "AKBNK": rate.akbnk = price
            default: break
            }
            if let price { extra[stock] = price }
        }
        rate.extraStocks = extra

        return rate
    }
}
