import Foundation

actor PriceService {
    static let shared = PriceService()

    // MARK: - BIST Hisseleri (Yahoo Finance)
    //
    // Yahoo Finance'in herkese açık "chart" uç noktası kayıt/API anahtarı
    // gerektirmez. BIST hisseleri ".IS" son ekiyle sorgulanır (ör. "TUPRS.IS").
    // CollectAPI'nin ücretli/anahtarlı modeli yerine kullanılıyor.

    private struct YahooChartResponse: Codable {
        let chart: YahooChart
    }
    private struct YahooChart: Codable {
        let result: [YahooResult]?
    }
    private struct YahooResult: Codable {
        let meta: YahooMeta
    }
    private struct YahooMeta: Codable {
        let regularMarketPrice: Double?
    }

    /// Yahoo Finance'ten herhangi bir sembolün güncel fiyatını çeker.
    private func fetchYahooQuote(symbol: String) async throws -> Double? {
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        // Yahoo, User-Agent olmayan istekleri reddedebiliyor.
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)
        return response.chart.result?.first?.meta.regularMarketPrice
    }

    func fetchBISTPrice(symbol: String) async throws -> Double? {
        if let price = try await fetchYahooQuote(symbol: "\(symbol).IS") {
            return price
        }
        // Yahoo Finance, BIST'in "Yapılandırılmış Ürünler ve Fon Pazarı"ndaki
        // gayrimenkul sertifikaları gibi niş enstrümanları kapsamıyor. Bilinen
        // semboller için borsa.doviz.com'dan (kayıt/anahtar gerektirmez) fallback
        // fiyat çekilir.
        if let slug = Self.dovizComSlugs[symbol] {
            return try await fetchDovizComPrice(slug: slug)
        }
        return nil
    }

    /// Yahoo Finance'te bulunamayan sembollerin borsa.doviz.com sayfa adları
    /// (URL slug'ları). Yeni bir enstrüman eklemek için buraya bir satır yeter.
    private static let dovizComSlugs: [String: String] = [
        "DMLKT": "dmlktg-emlak-konut-damla-kent-gms"
    ]

    /// borsa.doviz.com'un ilgili hisse sayfasındaki `<meta name="description">`
    /// etiketinden ("<Kod> hissesinin fiyatı X liradır") güncel fiyatı çıkarır.
    /// Sayfa sunucu tarafında render edildiği için JavaScript çalıştırmaya gerek yok.
    private func fetchDovizComPrice(slug: String) async throws -> Double? {
        guard let url = URL(string: "https://borsa.doviz.com/hisseler/\(slug)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else { return nil }

        let pattern = #"name="description" content="[^"]*fiyat[ıi] ([\d.,]+) liradır"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
            let range = Range(match.range(at: 1), in: html)
        else { return nil }

        let raw = String(html[range])
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(raw)
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
    func fetchAllPrices(previous: ExchangeRate? = nil, portfolioSymbols: Set<String> = []) async -> ExchangeRate {
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

        // BIST hisseleri — kullanıcının Hisse Senedi Kataloğu'ndan (Ayarlar)
        // VE portföyde fiilen elinde bulunan (transactions'tan gelen) tüm
        // hisselerden birleşik olarak okunur. Böylece bir hisseyi kataloğa
        // eklemeyi unutsanız bile (ör. PDF'den içe aktarılan bir işlem),
        // elinizdeki hisse yine de canlı fiyat takibine dahil olur.
        let catalogList = UserDefaults.standard.stringArray(forKey: "stockKey")
            ?? ["KCHOL", "TUPRS", "THYAO", "ALFAS", "ARCLK", "AKBNK"]
        let catalog = Array(Set(catalogList).union(portfolioSymbols)).sorted()

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
