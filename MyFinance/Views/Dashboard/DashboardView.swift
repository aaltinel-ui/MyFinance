import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \Transaction.tarih) private var transactions: [Transaction]
    @Query(sort: \ExchangeRate.tarih) private var exchangeRates: [ExchangeRate]
    @State private var calculator = PortfolioCalculator()
    @State private var isRefreshing = false

    private var latestRate: ExchangeRate? { exchangeRates.last }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    totalSummaryCard
                    kasaCardsSection
                    portfolioDistributionChart
                    topPositionsSection
                    recentTransactionsSection
                }
                .padding()
            }
            .navigationTitle("MyFinans")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await refreshPrices() }
                    } label: {
                        Label("Güncelle", systemImage: isRefreshing ? "arrow.clockwise" : "arrow.triangle.2.circlepath")
                    }
                    .disabled(isRefreshing)
                }
            }
            .onAppear { recalculate() }
            .onChange(of: transactions.count) { recalculate() }
            .onChange(of: exchangeRates.count) { recalculate() }
        }
    }

    private var totalSummaryCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Toplam Varlığım")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(Formatters.formatCurrency(calculator.portfolioSummary.toplamDeger))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                KZBadge(
                    value: calculator.portfolioSummary.karZarar,
                    percentage: calculator.portfolioSummary.karZararYuzdesi
                )
                HStack {
                    Text("Maliyet:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(Formatters.formatCurrency(calculator.portfolioSummary.toplamMaliyet))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
    }

    private var kasaCardsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kasalarım")
                .font(.headline)
                .padding(.leading, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(calculator.kasaSummaries) { kasa in
                        NavigationLink(destination: KasaDetailView(kasaTip: kasa.kasaTip, calculator: calculator)) {
                            kasaCard(kasa)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func kasaCard(_ kasa: KasaSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if let kt = KasaTip(rawValue: kasa.kasaTip) {
                        Image(systemName: kt.icon)
                            .foregroundStyle(Color.forKasa(kasa.kasaTip))
                    }
                    Text(kasa.kasaTip)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Text(Formatters.formatCurrency(kasa.guncelDeger))
                    .font(.title3)
                    .fontWeight(.bold)
                KZBadge(value: kasa.karZarar, percentage: kasa.karZararYuzdesi)
            }
            .frame(minWidth: 150)
        }
    }

    private var portfolioDistributionChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Portföy Dağılımı")
                    .font(.headline)
                Chart(calculator.typeSummaries) { ts in
                    SectorMark(
                        angle: .value("Değer", ts.guncelDeger),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(Color.forType(ts.tip))
                    .annotation(position: .overlay) {
                        let pct = calculator.portfolioSummary.toplamDeger > 0
                            ? ts.guncelDeger / calculator.portfolioSummary.toplamDeger * 100
                            : 0
                        if pct > 5 {
                            VStack(spacing: 0) {
                                Text(ts.tip)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                Text("%\(Int(pct))")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 220)

                ForEach(calculator.typeSummaries) { ts in
                    HStack {
                        Circle()
                            .fill(Color.forType(ts.tip))
                            .frame(width: 10, height: 10)
                        Text(ts.tip)
                            .font(.caption)
                        Spacer()
                        Text(Formatters.formatCurrency(ts.guncelDeger))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }

    private var topPositionsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("En Büyük Pozisyonlar")
                    .font(.headline)
                ForEach(Array(calculator.positions.prefix(5))) { pos in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(pos.islem)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(pos.tip)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(Formatters.formatCurrency(pos.guncelDeger))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            KZBadge(value: pos.karZarar, percentage: pos.karZararYuzdesi)
                        }
                    }
                    if pos.id != calculator.positions.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var recentTransactionsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Son Hareketler")
                    .font(.headline)
                ForEach(Array(transactions.suffix(5).reversed())) { tx in
                    HStack {
                        Image(systemName: tx.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(tx.isPositive ? .green : .red)
                        VStack(alignment: .leading) {
                            Text(tx.islem)
                                .font(.subheadline)
                            Text(Formatters.formatDate(tx.tarih))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(tx.isPositive ? "+" : "-")\(Formatters.formatCurrency(tx.tutarTL))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(tx.isPositive ? .green : .red)
                    }
                    if tx.id != transactions.suffix(5).reversed().first(where: { _ in true })?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func recalculate() {
        calculator.calculate(transactions: transactions, latestRates: latestRate)
    }

    @MainActor
    private func refreshPrices() async {
        isRefreshing = true
        _ = await PriceService.shared.fetchAllPrices()
        isRefreshing = false
    }
}
