import SwiftUI
import SwiftData

// MARK: - Portföy Raporu
//
// İki kademeli akordiyon:
//  1. Tip grubu (HİSSE, ALTIN, COIN …)  — dokunarak açılır/kapanır
//  2. Pozisyon satırı (TUPRS, THYAO …)   — dokunarak açılır/kapanır
//
// Her seviyede: toplam adet · maliyet · güncel değer · K/Z gösterilir.

struct PortfolioReportView: View {

    @AppStorage("hideBalances") private var hideBalances = false
    @Query(sort: \Transaction.tarih) private var transactions: [Transaction]
    @Query(sort: \ExchangeRate.tarih) private var exchangeRates: [ExchangeRate]
    @State private var calculator = PortfolioCalculator()

    /// Hangi BirimTip grupları açık?
    @State private var expandedTypes: Set<String> = []
    // (artık 2. kademe akordiyon yok — düz liste)

    private var latestRate: ExchangeRate? { exchangeRates.last }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    overallCard
                    tipBazliOzet

                    ForEach(calculator.typeSummaries) { ts in
                        tipGrubu(ts)
                    }
                }
                .padding()
            }
            .navigationTitle("Portföy Raporu")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            let allTypes = Set(calculator.typeSummaries.map(\.tip))
                            if expandedTypes == allTypes { expandedTypes.removeAll() }
                            else                         { expandedTypes = allTypes }
                        }
                    } label: {
                        Image(systemName: expandedTypes.isEmpty ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    }
                }
            }
            .onAppear { recalculate() }
            .onChange(of: transactions.count) { recalculate() }
            .onChange(of: exchangeRates.count) { recalculate() }
            .onReceive(NotificationCenter.default.publisher(for: .myFinanceDataDownloaded)) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { recalculate() }
            }
        }
    }

    private func recalculate() {
        calculator.calculate(transactions: transactions, latestRates: latestRate)
    }

    // MARK: - Üst Özet Kartı

    private var overallCard: some View {
        CardView {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "briefcase.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    Text("Toplam Portföy")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    KZBadge(
                        value: calculator.portfolioSummary.karZarar,
                        percentage: calculator.portfolioSummary.karZararYuzdesi
                    )
                }

                Divider()

                HStack {
                    statBlock(label: "Maliyet",
                              value: masked(calculator.portfolioSummary.toplamMaliyet),
                              icon: "banknote", color: .secondary)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Spacer()
                    statBlock(label: "Güncel Değer",
                              value: masked(calculator.portfolioSummary.toplamDeger),
                              icon: "chart.bar.fill",
                              color: calculator.portfolioSummary.karZarar >= 0 ? .green : .red,
                              align: .trailing)
                }
            }
        }
    }

    /// Tip bazlı mini özet (progress bar'lar)
    private var tipBazliOzet: some View {
        let toplam = calculator.portfolioSummary.toplamDeger
        guard toplam > 0 else { return AnyView(EmptyView()) }

        return AnyView(
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dağılım")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(calculator.typeSummaries) { ts in
                        VStack(spacing: 4) {
                            HStack {
                                if let bt = BirimTip(rawValue: ts.tip) {
                                    Image(systemName: bt.icon)
                                        .font(.caption)
                                        .foregroundStyle(Color.forType(ts.tip))
                                        .frame(width: 18)
                                }
                                Text(ts.tip)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                                let pct = ts.guncelDeger / toplam * 100
                                Text("%\(String(format: "%.1f", pct))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(masked(ts.guncelDeger))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .frame(width: 90, alignment: .trailing)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.secondary.opacity(0.12))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.forType(ts.tip))
                                        .frame(width: geo.size.width * (ts.guncelDeger / toplam), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        )
    }

    // MARK: - Tip Grubu (1. kademe akordiyon)

    private func tipGrubu(_ ts: TypeSummary) -> some View {
        let isOpen   = expandedTypes.contains(ts.tip)
        // Konsolide: aynı enstrüman farklı kasalarda olsa tek satır
        let consPos  = calculator.consolidatedPositions(tip: ts.tip)

        return CardView {
            VStack(spacing: 0) {

                // ── Başlık ──────────────────────────────────────────────
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
                                    .font(.body)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(ts.tip)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("\(consPos.count) enstrüman")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
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

                // ── Açık içerik ─────────────────────────────────────────
                if isOpen {
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.vertical, 10)

                        // Tip özeti (maliyet / güncel)
                        HStack(spacing: 16) {
                            tipStat("Maliyet", value: masked(ts.toplamMaliyet))
                            Spacer()
                            tipStat("Güncel Değer", value: masked(ts.guncelDeger), align: .trailing)
                        }
                        .padding(.bottom, 10)

                        // Konsolide pozisyon listesi
                        ForEach(Array(consPos.enumerated()), id: \.offset) { idx, pos in
                            pozisyonRow(pos: pos, showDivider: idx > 0)
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

    // MARK: - Pozisyon Satırı (düz liste, tıklama yok)

    private func pozisyonRow(pos: InstrumentPosition, showDivider: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if showDivider {
                Divider().padding(.vertical, 10)
            }

            // ── 1. Satır: Hisse adı + Toplam adet ───────────────────
            HStack(alignment: .firstTextBaseline) {
                Text(pos.islem)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(Formatters.formatDecimal(pos.toplamAdet)) adet")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 6)

            // ── 2. Satır: Maliyet → Güncel Değer ────────────────────
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Maliyet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(masked(pos.toplamMaliyet))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Güncel Değer")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(masked(pos.guncelDeger))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                Spacer()
                KZBadge(value: pos.karZarar, percentage: pos.karZararYuzdesi)
            }

            // ── 3. Satır: Ort. alış fiyatı → Güncel fiyat ───────────
            HStack(spacing: 4) {
                Text("Ort. \(Formatters.formatCurrencyDetailed(pos.ortalamaAlisFiyati))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(Formatters.formatCurrencyDetailed(pos.guncelFiyat))
                    .font(.caption2)
                    .foregroundStyle(pos.isKarda ? .green : .red)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Küçük Yardımcılar

    private func detayRow(_ label: String, _ icon: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }

    private func tipStat(_ label: String, value: String, align: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: align, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }

    private func statBlock(label: String, value: String, icon: String, color: Color, align: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: align, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    private func masked(_ value: Double) -> String {
        hideBalances ? "₺ ***" : Formatters.formatCurrency(value)
    }
}
