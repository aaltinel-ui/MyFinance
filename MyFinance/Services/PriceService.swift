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

    func fetchAllPrices() async -> ExchangeRate {
        let rate = ExchangeRate(tarih: Date())

        async let goldTask = try? fetchGoldPrices()
        async let currencyTask = try? fetchCurrencyRates()
        async let cryptoTask = try? fetchCryptoPrices()

        let gold = await goldTask
        let currency = await currencyTask
        let crypto = await cryptoTask

        rate.altinGram = gold?.gram
        rate.ceyrekAltin = gold?.ceyrek
        rate.yarimAltin = gold?.yarim
        rate.cumhuriyetAltin = gold?.cumhuriyet
        rate.euro = currency?.eur
        rate.usd = currency?.usd
        rate.bitcoinTRY = crypto?.btc
        rate.ethTRY = crypto?.eth

        // BIST stocks - fetch individually
        let stocks = ["KCHOL", "TUPRS", "THYAO", "ALFAS", "ARCLK", "AKBNK"]
        for stock in stocks {
            if let price = try? await fetchBISTPrice(symbol: stock) {
                switch stock {
                case "KCHOL": rate.kchol = price
                case "TUPRS": rate.tuprs = price
                case "THYAO": rate.thyao = price
                case "ALFAS": rate.alfas = price
                case "ARCLK": rate.arclk = price
                case "AKBNK": rate.akbnk = price
                default: break
                }
            }
        }

        return rate
    }
}
