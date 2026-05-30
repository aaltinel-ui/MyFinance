import SwiftUI
import SwiftData
import Charts

// MARK: - Saklama Bazlı Rapor
//
// Her saklama yeri (Banka, BINANCETR, Evde, BABAM) bir akordiyon grubu.
// Grup açıldığında o yerde tutulan pozisyonlar listelenir.

struct SaklamaReportView: View {

    @AppStorage("hideBalances") private var hideBalances = false
    @Query(sort: \Transaction.tarih) private var transactions: [Transaction]
    @Query(sort: \ExchangeRate.tarih) private var exchangeRates: [ExchangeRate]
    @State private var calculator = PortfolioCalculator()

    /// Hangi saklama yerleri açık?
    @State private var expandedYer: Set<String> = []
    /// Açıldığında kaydırılacak hedef
    @State private var acilanHedef: String?

    private var latestRate: ExchangeRate? { exchangeRates.last }
    private var toplamDeger: Double { calculator.saklamaSummaries.reduce(0) { $0 + $1.guncelDeger } }

    /// Header, lejant ve grafik için ortak aç/kapa.
    private func toggleYer(_ key: String) {
        withAnimation(.easeInOut(duration: 0.22)) {
            if expandedYer.contains(key) {
                expandedYer.remove(key)
            } else {
                expandedYer.insert(key)
                acilanHedef = key
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 14) {
                    overallCard
                    yerDagilimi

                    ForEach(calculator.saklamaSummaries) { sk in
                        yerGrubu(sk)
                            .id(sk.saklamaYeri)
                    }
                }
                .padding()
            }
            .onChange(of: acilanHedef) { _, hedef in
                guard let hedef else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(hedef, anchor: .top)
                }
                DispatchQueue.main.async { acilanHedef = nil }
            }
        }
        .navigationTitle("Saklama Bazlı Rapor")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        let all = Set(calculator.saklamaSummaries.map(\.saklamaYeri))
                        if expandedYer == all { expandedYer.removeAll() }
                        else                   { expandedYer = all }
                    }
                } label: {
                    Image(systemName: expandedYer.isEmpty ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
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

    private func recalculate() {
        calculator.calculate(transactions: transactions, latestRates: latestRate)
    }

    // MARK: - Üst Özet

    private var overallCard: some View {
        let maliyet = calculator.saklamaSummaries.reduce(0) { $0 + $1.toplamMaliyet }
        let deger   = toplamDeger
        let kz      = deger - maliyet
        let kzPct   = maliyet > 0 ? kz / maliyet * 100 : 0

        return CardView {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "archivebox.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    Text("Tüm Saklama Yerleri")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    KZBadge(value: kz, percentage: kzPct)
                }

                Divider()

                HStack {
                    statBlock(label: "Maliyet", value: masked(maliyet),
                              icon: "banknote", color: .secondary)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary).font(.caption)
                    Spacer()
                    statBlock(label: "Güncel Değer", value: masked(deger),
                              icon: "chart.bar.fill",
                              color: kz >= 0 ? .green : .red, align: .trailing)
                }
            }
        }
    }

    // MARK: - Saklama Yeri Dağılımı (pasta + bar)

    private var yerDagilimi: some View {
        guard toplamDeger > 0 else { return AnyView(EmptyView()) }

        return AnyView(
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Saklama Yeri Dağılımı")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Chart(calculator.saklamaSummaries) { sk in
                        SectorMark(
                            angle: .value("Değer", sk.guncelDeger),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(Color.forSaklama(sk.saklamaYeri))
                        .opacity(expandedYer.isEmpty || expandedYer.contains(sk.saklamaYeri) ? 1.0 : 0.35)
                        .annotation(position: .overlay) {
                            let pct = sk.guncelDeger / toplamDeger * 100
                            VStack(spacing: 1) {
                                if pct > 5 {
                                    Text("%\(Int(pct))")
                                        .font(.caption2).fontWeight(.bold)
                                }
                                if pct > 11 {
                                    Text(sk.saklamaYeri)
                                        .font(.system(size: 8)).fontWeight(.semibold)
                                        .lineLimit(1)
                                }
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    .frame(height: 220)
                    .chartOverlay { _ in
                        GeometryReader { geo in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .onTapGesture(coordinateSpace: .local) { loc in
                                    if let y = yerForTap(loc, in: geo.size) {
                                        toggleYer(y)
                                    }
                                }
                        }
                    }

                    ForEach(calculator.saklamaSummaries) { sk in
                        Button {
                            toggleYer(sk.saklamaYeri)
                        } label: {
                            HStack {
                                if let yer = SaklamaYeri(rawValue: sk.saklamaYeri) {
                                    Image(systemName: yer.icon)
                                        .font(.caption)
                                        .foregroundStyle(Color.forSaklama(sk.saklamaYeri))
                                        .frame(width: 18)
                                }
                                Text(sk.saklamaYeri)
                                    .font(.caption).fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Spacer()
                                let pct = sk.guncelDeger / toplamDeger * 100
                                Text("%\(String(format: "%.1f", pct))")
                                    .font(.caption2).foregroundStyle(.secondary)
                                Text(masked(sk.guncelDeger))
                                    .font(.caption).fontWeight(.medium)
                                    .frame(width: 100, alignment: .trailing)
                                Image(systemName: "chevron.right")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(expandedYer.contains(sk.saklamaYeri) ? Color.forSaklama(sk.saklamaYeri).opacity(0.12) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        )
    }

    /// Pasta grafikte seçilen açıyı saklama yeri adına çevirir.
    private func yerForAngle(_ value: Double?) -> String? {
        guard let value else { return nil }
        var cum = 0.0
        for sk in calculator.saklamaSummaries {
            cum += sk.guncelDeger
            if value <= cum { return sk.saklamaYeri }
        }
        return nil
    }

    /// Donut üzerindeki dokunma konumunu saklama yeri adına çevirir (sadece halka bölgesinde).
    private func yerForTap(_ loc: CGPoint, in size: CGSize) -> String? {
        guard toplamDeger > 0 else { return nil }
        let cx = size.width / 2, cy = size.height / 2
        let dx = loc.x - cx, dy = loc.y - cy
        let dist = (dx * dx + dy * dy).squareRoot()
        let outer = min(size.width, size.height) / 2
        let inner = outer * 0.6
        guard dist >= inner * 0.55, dist <= outer * 1.1 else { return nil }
        var ang = atan2(dx, -dy)
        if ang < 0 { ang += 2 * .pi }
        let val = ang / (2 * .pi) * toplamDeger
        return yerForAngle(val)
    }

    // MARK: - Saklama Yeri Grubu (akordiyon)

    private func yerGrubu(_ sk: SaklamaOzeti) -> some View {
        let isOpen = expandedYer.contains(sk.saklamaYeri)
        let poz = sk.positions.sorted { $0.guncelDeger > $1.guncelDeger }

        return CardView {
            VStack(spacing: 0) {
                // ── Başlık ──
                Button {
                    toggleYer(sk.saklamaYeri)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.forSaklama(sk.saklamaYeri).opacity(0.12))
                                .frame(width: 36, height: 36)
                            if let yer = SaklamaYeri(rawValue: sk.saklamaYeri) {
                                Image(systemName: yer.icon)
                                    .foregroundStyle(Color.forSaklama(sk.saklamaYeri))
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sk.saklamaYeri)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("\(poz.count) enstrüman")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(masked(sk.guncelDeger))
                                .font(.body).fontWeight(.semibold)
                            KZBadge(value: sk.karZarar, percentage: sk.karZararYuzdesi)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption).fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isOpen ? 90 : 0))
                            .animation(.easeInOut(duration: 0.22), value: isOpen)
                            .padding(.leading, 2)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                // ── Açık içerik ──
                if isOpen {
                    VStack(spacing: 0) {
                        Divider().padding(.vertical, 10)

                        HStack(spacing: 16) {
                            tipStat("Maliyet", value: masked(sk.toplamMaliyet))
                            Spacer()
                            tipStat("Güncel Değer", value: masked(sk.guncelDeger), align: .trailing)
                        }
                        .padding(.bottom, 10)

                        ForEach(Array(poz.enumerated()), id: \.offset) { idx, pos in
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

    // MARK: - Pozisyon Satırı

    private func pozisyonRow(pos: InstrumentPosition, showDivider: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if showDivider { Divider().padding(.vertical, 10) }

            HStack(alignment: .firstTextBaseline) {
                Text(pos.islem)
                    .font(.body).fontWeight(.bold).foregroundStyle(.primary)
                if let bt = BirimTip(rawValue: pos.tip) {
                    Image(systemName: bt.icon)
                        .font(.caption2)
                        .foregroundStyle(Color.forType(pos.tip))
                }
                Spacer()
                Text("\(Formatters.formatDecimal(pos.toplamAdet)) adet")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
            }
            .padding(.bottom, 6)

            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Maliyet").font(.caption2).foregroundStyle(.secondary)
                    Text(masked(pos.toplamMaliyet)).font(.caption).fontWeight(.medium)
                }
                Image(systemName: "arrow.right")
                    .font(.caption2).foregroundStyle(.secondary).padding(.horizontal, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Güncel Değer").font(.caption2).foregroundStyle(.secondary)
                    Text(masked(pos.guncelDeger)).font(.caption).fontWeight(.medium)
                }
                Spacer()
                KZBadge(value: pos.karZarar, percentage: pos.karZararYuzdesi)
            }

            HStack(spacing: 4) {
                Text("Ort. \(Formatters.formatCurrencyDetailed(pos.ortalamaAlisFiyati))")
                    .font(.caption2).foregroundStyle(.secondary)
                Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                Text(Formatters.formatCurrencyDetailed(pos.guncelFiyat))
                    .font(.caption2).foregroundStyle(pos.isKarda ? .green : .red)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Yardımcılar

    private func tipStat(_ label: String, value: String, align: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: align, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption).fontWeight(.semibold)
        }
    }

    private func statBlock(label: String, value: String, icon: String, color: Color, align: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: align, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body).fontWeight(.semibold).foregroundStyle(color)
        }
    }

    private func masked(_ value: Double) -> String {
        hideBalances ? "₺ ***" : Formatters.formatCurrency(value)
    }
}
