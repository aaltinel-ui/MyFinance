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
    @AppStorage("hideBalances") private var hideBalances = false
    // Tip grubu akordiyon: tip adı → açık mı?
    @State private var expandedTypes: Set<String> = []
    // Enstrüman akordiyon: "tip|islem" → açık mı?
    @State private var expandedInstrument: Set<String> = []

    private var latestRate: ExchangeRate? { exchangeRates.last }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalSummaryCard
                    portfolioDistributionChart
                    portfoyTipleriSection
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
                // @Query'nin SwiftData değişikliğini alması için kısa gecikme
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    recalculate()
                }
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
                            let pct = calculator.portfolioSummary.toplamDeger > 0
                                ? ts.guncelDeger / calculator.portfolioSummary.toplamDeger * 100
                                : 0
                            Text("%\(Int(pct))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(selectedType == ts.tip ? Color.forType(ts.tip).opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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

    // MARK: - Portföy (Tip Bazlı Akordiyon)

    private var portfoyTipleriSection: some View {
        VStack(spacing: 14) {
            if calculator.typeSummaries.isEmpty {
                CardView {
                    Text("Portföy pozisyonu bulunamadı.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            } else {
                ForEach(calculator.typeSummaries) { ts in
                    tipGrubuCard(ts)
                }
            }
        }
    }

    private func tipGrubuCard(_ ts: TypeSummary) -> some View {
        let isOpen  = expandedTypes.contains(ts.tip)
        let consPoz = calculator.consolidatedPositions(tip: ts.tip)

        return CardView {
            VStack(alignment: .leading, spacing: 0) {
                // — Tip başlığı (1. kademe akordiyon) —
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        if isOpen { expandedTypes.remove(ts.tip) }
                        else      { expandedTypes.insert(ts.tip) }
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.forType(ts.tip).opacity(0.12))
                                .frame(width: 36, height: 36)
                            if let bt = BirimTip(rawValue: ts.tip) {
                                Image(systemName: bt.icon)
                                    .foregroundStyle(Color.forType(ts.tip))
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ts.tip)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            Text("\(consPoz.count) enstrüman")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(masked(ts.guncelDeger))
                                .font(.body)
                                .fontWeight(.semibold)
                            KZBadge(value: ts.karZarar, percentage: ts.karZararYuzdesi)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isOpen ? 90 : 0))
                            .animation(.easeInOut(duration: 0.22), value: isOpen)
                            .padding(.leading, 2)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                // — Konsolide enstrüman listesi —
                if isOpen {
                    VStack(spacing: 0) {
                        Divider().padding(.top, 8)
                        ForEach(Array(consPoz.enumerated()), id: \.offset) { index, pos in
                            enstrumanRow(pos: pos, tip: ts.tip, showDivider: index > 0)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal:   .opacity.combined(with: .move(edge: .top))
                    ))
                }
            }
        }
    }

    // Enstrüman akordiyon anahtarı: "tip|islem" (konsolide)
    private func enstrumanKey(_ pos: InstrumentPosition, tip: String) -> String { "\(tip)|\(pos.islem)" }

    private func enstrumanRow(pos: InstrumentPosition, tip: String, showDivider: Bool) -> some View {
        let key        = enstrumanKey(pos, tip: tip)
        let isExpanded = expandedInstrument.contains(key)
        let kasaList   = calculator.kasaBreakdown(islem: pos.islem, tip: tip)

        return VStack(spacing: 0) {
            if showDivider { Divider() }

            // — Özet satırı —
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    if isExpanded { expandedInstrument.remove(key) }
                    else          { expandedInstrument.insert(key) }
                }
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pos.islem)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        // Toplam adet her zaman görünür
                        HStack(spacing: 6) {
                            Text("\(Formatters.formatDecimal(pos.toplamAdet)) adet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if kasaList.count > 1 {
                                Text("\(kasaList.count) kasa")
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(Capsule())
                            } else if let k = kasaList.first {
                                Text(k.kasaTip)
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.forKasa(k.kasaTip).opacity(0.15))
                                    .foregroundStyle(Color.forKasa(k.kasaTip))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(masked(pos.guncelDeger))
                            .font(.body)
                            .fontWeight(.medium)
                        KZBadge(value: pos.karZarar, percentage: pos.karZararYuzdesi)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.22), value: isExpanded)
                        .padding(.leading, 2)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // — Detay paneli —
            if isExpanded {
                VStack(spacing: 0) {
                    hisseDetailRow("Toplam Adet",   icon: "number",
                                   value: Formatters.formatDecimal(pos.toplamAdet), color: .primary)
                    hisseDetailRow("Ort. Alış",     icon: "arrow.down.circle",
                                   value: Formatters.formatCurrencyDetailed(pos.ortalamaAlisFiyati), color: .primary)
                    hisseDetailRow("Güncel Fiyat",  icon: "chart.line.uptrend.xyaxis",
                                   value: Formatters.formatCurrencyDetailed(pos.guncelFiyat), color: .primary)
                    hisseDetailRow("Maliyet",       icon: "banknote",
                                   value: masked(pos.toplamMaliyet), color: .primary)
                    hisseDetailRow("Güncel Değer",  icon: "chart.bar.fill",
                                   value: masked(pos.guncelDeger), color: .primary)
                    hisseDetailRow("Kar / Zarar",
                                   icon: pos.isKarda ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                                   value: (pos.isKarda ? "+" : "") + masked(pos.karZarar),
                                   color: pos.isKarda ? .green : .red)

                    // Birden fazla kasada varsa dağılım göster
                    if kasaList.count > 1 {
                        Divider().padding(.vertical, 6)
                        Text("Kasa Dağılımı")
                            .font(.caption2).fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)
                        ForEach(kasaList) { k in
                            HStack {
                                Text(k.kasaTip)
                                    .font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.forKasa(k.kasaTip).opacity(0.15))
                                    .foregroundStyle(Color.forKasa(k.kasaTip))
                                    .clipShape(Capsule())
                                Text("\(Formatters.formatDecimal(k.toplamAdet)) adet")
                                    .font(.caption2).foregroundStyle(.secondary)
                                Spacer()
                                Text(masked(k.guncelDeger))
                                    .font(.caption2).fontWeight(.medium)
                                KZBadge(value: k.karZarar, percentage: k.karZararYuzdesi)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.bottom, 8)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal:   .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
    }

    private func hisseDetailRow(_ label: String, icon: String, value: String, color: Color) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
        .padding(.vertical, 5)
    }

    private var topPositionsSection: some View {
        // Konsolide: aynı enstrüman tüm kasalarda toplanıp tek satır
        let topPoz = Array(calculator.consolidatedPositions().prefix(5))
        return CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("En Büyük Pozisyonlar")
                    .font(.title3)
                    .fontWeight(.bold)
                ForEach(Array(topPoz.enumerated()), id: \.offset) { index, pos in
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
                    if index < topPoz.count - 1 {
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
