import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \Transaction.tarih) private var transactions: [Transaction]
    @Query(sort: \ExchangeRate.tarih) private var exchangeRates: [ExchangeRate]
    @State private var calculator = PortfolioCalculator()
    @State private var isRefreshing = false
    @State private var selectedType: String?
    @State private var chartAngleSelection: Double?
    @State private var selectedKasa: String?
    @State private var kasaChartAngleSelection: Double?
    @AppStorage("hideBalances") private var hideBalances = false

    private var latestRate: ExchangeRate? { exchangeRates.last }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalSummaryCard
                    kasaCardsSection
                    portfolioDistributionChart
                    kasaDistributionChart
                    topPositionsSection
                    recentTransactionsSection
                }
                .padding()
            }
            .refreshable {
                await refreshPrices()
            }
            .navigationTitle("MyFinans")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        withAnimation { hideBalances.toggle() }
                    } label: {
                        Image(systemName: hideBalances ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(hideBalances ? .red : .primary)
                    }
                }
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
            .onReceive(NotificationCenter.default.publisher(for: .myFinanceDataDownloaded)) { _ in
                recalculate()
            }
        }
    }

    private var totalSummaryCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Toplam Varlığım")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text(masked(calculator.portfolioSummary.toplamDeger))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                KZBadge(
                    value: calculator.portfolioSummary.karZarar,
                    percentage: calculator.portfolioSummary.karZararYuzdesi
                )
                HStack {
                    Text("Maliyet:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(masked(calculator.portfolioSummary.toplamMaliyet))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }

    private var kasaCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kasalarım")
                .font(.title3)
                .fontWeight(.bold)
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let kt = KasaTip(rawValue: kasa.kasaTip) {
                        Image(systemName: kt.icon)
                            .font(.title3)
                            .foregroundStyle(Color.forKasa(kasa.kasaTip))
                    }
                    Text(kasa.kasaTip)
                        .font(.body)
                        .fontWeight(.medium)
                }
                Text(masked(kasa.guncelDeger))
                    .font(.title2)
                    .fontWeight(.bold)
                KZBadge(value: kasa.karZarar, percentage: kasa.karZararYuzdesi)
            }
            .frame(minWidth: 180)
        }
    }

    private var portfolioDistributionChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Portföy Dağılımı")
                    .font(.title3)
                    .fontWeight(.bold)
                Chart(calculator.typeSummaries) { ts in
                    SectorMark(
                        angle: .value("Değer", ts.guncelDeger),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(Color.forType(ts.tip))
                    .opacity(selectedType == nil || selectedType == ts.tip ? 1.0 : 0.4)
                    .annotation(position: .overlay) {
                        let pct = calculator.portfolioSummary.toplamDeger > 0
                            ? ts.guncelDeger / calculator.portfolioSummary.toplamDeger * 100
                            : 0
                        if pct > 5 {
                            VStack(spacing: 2) {
                                Text(ts.tip)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("%\(Int(pct))")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 260)
                .chartAngleSelection(value: $chartAngleSelection)
                .onChange(of: chartAngleSelection) { _, newValue in
                    selectedType = findType(for: newValue)
                }

                ForEach(calculator.typeSummaries) { ts in
                    Button {
                        withAnimation {
                            selectedType = selectedType == ts.tip ? nil : ts.tip
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color.forType(ts.tip))
                                .frame(width: 12, height: 12)
                            Text(ts.tip)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(masked(ts.guncelDeger))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(selectedType == ts.tip ? Color.forType(ts.tip).opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                if let selected = selectedType {
                    typeDetailSection(for: selected)
                }
            }
        }
    }

    private var kasaDistributionChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Kasa Dağılımı")
                    .font(.title3)
                    .fontWeight(.bold)
                Chart(calculator.kasaSummaries) { ks in
                    SectorMark(
                        angle: .value("Değer", ks.guncelDeger),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(Color.forKasa(ks.kasaTip))
                    .opacity(selectedKasa == nil || selectedKasa == ks.kasaTip ? 1.0 : 0.4)
                    .annotation(position: .overlay) {
                        let pct = calculator.portfolioSummary.toplamDeger > 0
                            ? ks.guncelDeger / calculator.portfolioSummary.toplamDeger * 100
                            : 0
                        if pct > 5 {
                            VStack(spacing: 2) {
                                Text(ks.kasaTip)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("%\(Int(pct))")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 260)
                .chartAngleSelection(value: $kasaChartAngleSelection)
                .onChange(of: kasaChartAngleSelection) { _, newValue in
                    selectedKasa = findKasa(for: newValue)
                }

                ForEach(calculator.kasaSummaries) { ks in
                    Button {
                        withAnimation {
                            selectedKasa = selectedKasa == ks.kasaTip ? nil : ks.kasaTip
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color.forKasa(ks.kasaTip))
                                .frame(width: 12, height: 12)
                            if let kt = KasaTip(rawValue: ks.kasaTip) {
                                Image(systemName: kt.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.forKasa(ks.kasaTip))
                            }
                            Text(ks.kasaTip)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(masked(ks.guncelDeger))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(selectedKasa == ks.kasaTip ? Color.forKasa(ks.kasaTip).opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                if let selected = selectedKasa {
                    kasaDetailSection(for: selected)
                }
            }
        }
    }

    private func findKasa(for value: Double?) -> String? {
        guard let value else { return nil }
        var cumulative: Double = 0
        for ks in calculator.kasaSummaries {
            cumulative += ks.guncelDeger
            if value <= cumulative {
                return ks.kasaTip
            }
        }
        return nil
    }

    private func kasaDetailSection(for kasaTip: String) -> some View {
        let positions = calculator.positions(for: kasaTip)
        let summary = calculator.kasaSummaries.first { $0.kasaTip == kasaTip }

        return VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack {
                Text("\(kasaTip) Detayı")
                    .font(.body)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    withAnimation { selectedKasa = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if let summary {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Maliyet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(masked(summary.toplamMaliyet))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Güncel Değer")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(masked(summary.guncelDeger))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    KZBadge(value: summary.karZarar, percentage: summary.karZararYuzdesi)
                }
            }

            ForEach(positions) { pos in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pos.islem)
                            .font(.body)
                            .fontWeight(.medium)
                        HStack(spacing: 6) {
                            Text(pos.tip)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(Formatters.formatDecimal(pos.toplamAdet)) adet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(masked(pos.guncelDeger))
                            .font(.body)
                            .fontWeight(.medium)
                        KZBadge(value: pos.karZarar, percentage: pos.karZararYuzdesi)
                    }
                }
                if pos.id != positions.last?.id {
                    Divider()
                }
            }
        }
        .padding(.top, 4)
    }

    private func findType(for value: Double?) -> String? {
        guard let value else { return nil }
        var cumulative: Double = 0
        for ts in calculator.typeSummaries {
            cumulative += ts.guncelDeger
            if value <= cumulative {
                return ts.tip
            }
        }
        return nil
    }

    private func typeDetailSection(for tip: String) -> some View {
        let positions = calculator.positions(for: nil, tip: tip)
        let summary = calculator.typeSummaries.first { $0.tip == tip }

        return VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack {
                Text("\(tip) Detayı")
                    .font(.body)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    withAnimation { selectedType = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if let summary {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Maliyet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(masked(summary.toplamMaliyet))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Güncel Değer")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(masked(summary.guncelDeger))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    KZBadge(value: summary.karZarar, percentage: summary.karZararYuzdesi)
                }
            }

            ForEach(positions) { pos in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pos.islem)
                            .font(.body)
                            .fontWeight(.medium)
                        Text("\(Formatters.formatDecimal(pos.toplamAdet)) adet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(masked(pos.guncelDeger))
                            .font(.body)
                            .fontWeight(.medium)
                        KZBadge(value: pos.karZarar, percentage: pos.karZararYuzdesi)
                    }
                }
                if pos.id != positions.last?.id {
                    Divider()
                }
            }
        }
        .padding(.top, 4)
    }

    private var topPositionsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("En Büyük Pozisyonlar")
                    .font(.title3)
                    .fontWeight(.bold)
                ForEach(Array(calculator.positions.prefix(5))) { pos in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pos.islem)
                                .font(.body)
                                .fontWeight(.medium)
                            Text(pos.tip)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(masked(pos.guncelDeger))
                                .font(.body)
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
            VStack(alignment: .leading, spacing: 10) {
                Text("Son Hareketler")
                    .font(.title3)
                    .fontWeight(.bold)
                ForEach(Array(transactions.suffix(5).reversed())) { tx in
                    HStack {
                        Image(systemName: tx.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(tx.isPositive ? .green : .red)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tx.islem)
                                .font(.body)
                            Text(Formatters.formatDate(tx.tarih))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(hideBalances ? "₺ ***" : "\(tx.isPositive ? "+" : "-")\(masked(tx.tutarTL))")
                            .font(.body)
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

    private func masked(_ value: Double) -> String {
        hideBalances ? "₺ ***" : Formatters.formatCurrency(value)
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
