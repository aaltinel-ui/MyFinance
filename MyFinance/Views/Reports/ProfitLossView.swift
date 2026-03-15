import SwiftUI
import SwiftData
import Charts

struct ProfitLossView: View {
    @Query(sort: \Transaction.tarih) private var transactions: [Transaction]
    @Query(sort: \ExchangeRate.tarih) private var exchangeRates: [ExchangeRate]
    @State private var calculator = PortfolioCalculator()
    @State private var selectedKasa: String?
    @State private var selectedTip: String?

    private var latestRate: ExchangeRate? { exchangeRates.last }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    overallKZCard
                    filterSection
                    kasaKZSection
                    tipKZSection
                    instrumentKZSection
                    topGainersLosers
                }
                .padding()
            }
            .navigationTitle("Kâr / Zarar")
            .onAppear { recalculate() }
            .onChange(of: transactions.count) { recalculate() }
        }
    }

    // MARK: - Overall K/Z
    private var overallKZCard: some View {
        CardView {
            VStack(spacing: 12) {
                Text("Toplam Kâr / Zarar")
                    .font(.headline)
                HStack(spacing: 24) {
                    VStack {
                        Text("Maliyet")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(Formatters.formatCurrency(calculator.portfolioSummary.toplamMaliyet))
                            .font(.title3).fontWeight(.medium)
                    }
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    VStack {
                        Text("Güncel Değer")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(Formatters.formatCurrency(calculator.portfolioSummary.toplamDeger))
                            .font(.title3).fontWeight(.medium)
                    }
                }
                KZBadge(
                    value: calculator.portfolioSummary.karZarar,
                    percentage: calculator.portfolioSummary.karZararYuzdesi
                )

                // K/Z bar chart
                let kz = calculator.portfolioSummary.karZarar
                HStack {
                    Text("Zarar")
                        .font(.caption2).foregroundStyle(.red)
                    GeometryReader { geo in
                        let mid = geo.size.width / 2
                        let barWidth = abs(kz) / max(calculator.portfolioSummary.toplamMaliyet, 1) * mid
                        ZStack {
                            Rectangle().fill(Color.gray.opacity(0.1))
                            if kz >= 0 {
                                HStack {
                                    Spacer()
                                        .frame(width: mid)
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: min(barWidth, mid))
                                    Spacer()
                                }
                            } else {
                                HStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: min(barWidth, mid))
                                    Spacer()
                                        .frame(width: mid)
                                }
                            }
                        }
                    }
                    .frame(height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text("Kâr")
                        .font(.caption2).foregroundStyle(.green)
                }
            }
        }
    }

    // MARK: - Filters
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                filterChip("Tümü", isSelected: selectedKasa == nil) { selectedKasa = nil }
                ForEach(KasaTip.allCases) { kasa in
                    filterChip(kasa.rawValue, isSelected: selectedKasa == kasa.rawValue) {
                        selectedKasa = selectedKasa == kasa.rawValue ? nil : kasa.rawValue
                    }
                }
            }
        }
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Kasa K/Z
    private var kasaKZSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Kasa Bazlı K/Z")
                    .font(.headline)
                ForEach(filteredKasaSummaries) { kasa in
                    VStack(spacing: 4) {
                        HStack {
                            Text(kasa.kasaTip)
                                .font(.subheadline).fontWeight(.medium)
                            Spacer()
                            KZBadge(value: kasa.karZarar, percentage: kasa.karZararYuzdesi)
                        }
                        HStack {
                            Text("Maliyet: \(Formatters.formatCurrency(kasa.toplamMaliyet))")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text("Güncel: \(Formatters.formatCurrency(kasa.guncelDeger))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Tip K/Z
    private var tipKZSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tip Bazlı K/Z")
                    .font(.headline)

                Chart(filteredTypeSummaries) { ts in
                    BarMark(
                        x: .value("K/Z", ts.karZarar),
                        y: .value("Tip", ts.tip)
                    )
                    .foregroundStyle(ts.karZarar >= 0 ? .green : .red)
                    .annotation(position: ts.karZarar >= 0 ? .trailing : .leading) {
                        Text(Formatters.formatCurrency(ts.karZarar))
                            .font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(Formatters.formatCurrency(v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(filteredTypeSummaries.count * 50 + 20))

                ForEach(filteredTypeSummaries) { ts in
                    HStack {
                        Circle()
                            .fill(Color.forType(ts.tip))
                            .frame(width: 10, height: 10)
                        Text(ts.tip)
                            .font(.caption)
                        Spacer()
                        Text("Maliyet: \(Formatters.formatCurrency(ts.toplamMaliyet))")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text("Güncel: \(Formatters.formatCurrency(ts.guncelDeger))")
                            .font(.caption2).foregroundStyle(.secondary)
                        KZBadge(value: ts.karZarar, percentage: ts.karZararYuzdesi)
                    }
                }
            }
        }
    }

    // MARK: - Instrument K/Z
    private var instrumentKZSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enstrüman Bazlı K/Z")
                    .font(.headline)
                ForEach(filteredPositions) { pos in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pos.islem)
                                .font(.subheadline).fontWeight(.medium)
                            Text("\(Formatters.formatDecimal(pos.toplamAdet)) adet")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 8) {
                                VStack(alignment: .trailing) {
                                    Text("Ort. Alış")
                                        .font(.caption2).foregroundStyle(.secondary)
                                    Text(Formatters.formatCurrencyDetailed(pos.ortalamaAlisFiyati))
                                        .font(.caption)
                                }
                                VStack(alignment: .trailing) {
                                    Text("Güncel")
                                        .font(.caption2).foregroundStyle(.secondary)
                                    Text(Formatters.formatCurrencyDetailed(pos.guncelFiyat))
                                        .font(.caption)
                                }
                            }
                            KZBadge(value: pos.karZarar, percentage: pos.karZararYuzdesi)
                        }
                    }
                    Divider()
                }
            }
        }
    }

    // MARK: - Top Gainers/Losers
    private var topGainersLosers: some View {
        HStack(alignment: .top, spacing: 12) {
            CardView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.green)
                        Text("En Çok Kâr")
                            .font(.subheadline).fontWeight(.medium)
                    }
                    ForEach(topGainers) { pos in
                        HStack {
                            Text(pos.islem)
                                .font(.caption)
                            Spacer()
                            Text(Formatters.formatPercent(pos.karZararYuzdesi))
                                .font(.caption).foregroundStyle(.green)
                        }
                    }
                }
            }
            CardView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.red)
                        Text("En Çok Zarar")
                            .font(.subheadline).fontWeight(.medium)
                    }
                    ForEach(topLosers) { pos in
                        HStack {
                            Text(pos.islem)
                                .font(.caption)
                            Spacer()
                            Text(Formatters.formatPercent(pos.karZararYuzdesi))
                                .font(.caption).foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed
    private var filteredPositions: [InstrumentPosition] {
        calculator.positions.filter { pos in
            (selectedKasa == nil || pos.kasaTip == selectedKasa) &&
            (selectedTip == nil || pos.tip == selectedTip)
        }
    }

    private var filteredTypeSummaries: [TypeSummary] {
        if selectedKasa == nil { return calculator.typeSummaries }
        let positions = calculator.positions(for: selectedKasa)
        var map: [String: TypeSummary] = [:]
        for pos in positions {
            if var ts = map[pos.tip] {
                ts.toplamMaliyet += pos.toplamMaliyet
                ts.guncelDeger += pos.guncelDeger
                map[pos.tip] = ts
            } else {
                map[pos.tip] = TypeSummary(tip: pos.tip, toplamMaliyet: pos.toplamMaliyet, guncelDeger: pos.guncelDeger)
            }
        }
        return map.values.sorted { $0.guncelDeger > $1.guncelDeger }
    }

    private var filteredKasaSummaries: [KasaSummary] {
        if let kasa = selectedKasa {
            return calculator.kasaSummaries.filter { $0.kasaTip == kasa }
        }
        return calculator.kasaSummaries
    }

    private var topGainers: [InstrumentPosition] {
        filteredPositions.filter { $0.isKarda }.sorted { $0.karZararYuzdesi > $1.karZararYuzdesi }.prefix(5).map { $0 }
    }

    private var topLosers: [InstrumentPosition] {
        filteredPositions.filter { !$0.isKarda }.sorted { $0.karZararYuzdesi < $1.karZararYuzdesi }.prefix(5).map { $0 }
    }

    private func recalculate() {
        calculator.calculate(transactions: transactions, latestRates: latestRate)
    }
}
