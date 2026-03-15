import SwiftUI
import SwiftData
import Charts

struct PortfolioChartView: View {
    @Query(sort: \Transaction.tarih) private var transactions: [Transaction]
    @Query(sort: \ExchangeRate.tarih) private var exchangeRates: [ExchangeRate]
    @State private var selectedTimeRange: TimeRange = .all
    @State private var calculator = PortfolioCalculator()
    @State private var pieMode: PieMode = .tip
    @State private var selectedPieItem: String?
    @State private var pieAngleSelection: Double?

    enum PieMode: String, CaseIterable {
        case tip = "Tip Bazında"
        case kasa = "Kasa Bazında"
    }

    enum TimeRange: String, CaseIterable {
        case oneMonth = "1 Ay"
        case threeMonths = "3 Ay"
        case sixMonths = "6 Ay"
        case oneYear = "1 Yıl"
        case all = "Tümü"

        var startDate: Date? {
            let cal = Calendar.current
            switch self {
            case .oneMonth: return cal.date(byAdding: .month, value: -1, to: Date())
            case .threeMonths: return cal.date(byAdding: .month, value: -3, to: Date())
            case .sixMonths: return cal.date(byAdding: .month, value: -6, to: Date())
            case .oneYear: return cal.date(byAdding: .year, value: -1, to: Date())
            case .all: return nil
            }
        }
    }

    private var filteredRates: [ExchangeRate] {
        guard let start = selectedTimeRange.startDate else { return exchangeRates }
        return exchangeRates.filter { $0.tarih >= start }
    }

    private var cumulativeValues: [(date: Date, value: Double)] {
        var cumulative: Double = 0
        var result: [(Date, Double)] = []

        let sortedTx = transactions.sorted { $0.tarih < $1.tarih }
        for tx in sortedTx {
            if let start = selectedTimeRange.startDate, tx.tarih < start { continue }
            cumulative += tx.signedTutar
            result.append((tx.tarih, cumulative))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    timeRangePicker
                    distributionPieChart
                    portfolioValueChart
                    investmentByTypeChart
                    monthlyFlowChart
                }
                .padding()
            }
            .navigationTitle("Portföy Grafikleri")
            .onAppear { recalculate() }
            .onChange(of: transactions.count) { recalculate() }
            .onChange(of: exchangeRates.count) { recalculate() }
        }
    }

    private func recalculate() {
        calculator.calculate(transactions: transactions, latestRates: exchangeRates.last)
    }

    private var timeRangePicker: some View {
        Picker("Zaman", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Pie Chart Data

    private struct PieSlice: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
    }

    private var pieSlices: [PieSlice] {
        switch pieMode {
        case .tip:
            return calculator.typeSummaries.map {
                PieSlice(label: $0.tip, value: $0.guncelDeger, color: Color.forType($0.tip))
            }
        case .kasa:
            return calculator.kasaSummaries.map {
                PieSlice(label: $0.kasaTip, value: $0.guncelDeger, color: Color.forKasa($0.kasaTip))
            }
        }
    }

    private var pieTotal: Double {
        pieSlices.reduce(0) { $0 + $1.value }
    }

    private func findPieItem(for value: Double?) -> String? {
        guard let value else { return nil }
        var cumulative: Double = 0
        for slice in pieSlices {
            cumulative += slice.value
            if value <= cumulative {
                return slice.label
            }
        }
        return nil
    }

    private func pieDetailSummary(for label: String) -> (maliyet: Double, deger: Double, kz: Double, kzPct: Double)? {
        switch pieMode {
        case .tip:
            if let ts = calculator.typeSummaries.first(where: { $0.tip == label }) {
                return (ts.toplamMaliyet, ts.guncelDeger, ts.karZarar, ts.karZararYuzdesi)
            }
        case .kasa:
            if let ks = calculator.kasaSummaries.first(where: { $0.kasaTip == label }) {
                return (ks.toplamMaliyet, ks.guncelDeger, ks.karZarar, ks.karZararYuzdesi)
            }
        }
        return nil
    }

    private func pieDetailPositions(for label: String) -> [InstrumentPosition] {
        switch pieMode {
        case .tip:
            return calculator.positions(for: nil, tip: label)
        case .kasa:
            return calculator.positions(for: label)
        }
    }

    // MARK: - Distribution Pie Chart

    private var distributionPieChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Portföy Dağılımı")
                    .font(.title3)
                    .fontWeight(.bold)

                Picker("Mod", selection: $pieMode) {
                    ForEach(PieMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: pieMode) { _, _ in
                    withAnimation {
                        selectedPieItem = nil
                        pieAngleSelection = nil
                    }
                }

                if pieSlices.isEmpty {
                    Text("Veri bulunamadı")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(height: 260)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart(pieSlices) { slice in
                        SectorMark(
                            angle: .value("Değer", slice.value),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(slice.color)
                        .opacity(selectedPieItem == nil || selectedPieItem == slice.label ? 1.0 : 0.35)
                        .annotation(position: .overlay) {
                            let pct = pieTotal > 0 ? slice.value / pieTotal * 100 : 0
                            if pct > 5 {
                                VStack(spacing: 2) {
                                    Text(slice.label)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    Text("%\(Int(pct))")
                                        .font(.caption)
                                    Text(Formatters.formatCurrency(slice.value))
                                        .font(.caption2)
                                }
                                .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(height: 280)
                    .chartAngleSelection(value: $pieAngleSelection)
                    .onChange(of: pieAngleSelection) { _, newValue in
                        withAnimation {
                            selectedPieItem = findPieItem(for: newValue)
                        }
                    }

                    // Legend
                    ForEach(pieSlices) { slice in
                        let pct = pieTotal > 0 ? slice.value / pieTotal * 100 : 0
                        Button {
                            withAnimation {
                                selectedPieItem = selectedPieItem == slice.label ? nil : slice.label
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(slice.color)
                                    .frame(width: 12, height: 12)
                                Text(slice.label)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("%\(Int(pct))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                                Text(Formatters.formatCurrency(slice.value))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                    .frame(width: 110, alignment: .trailing)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(selectedPieItem == slice.label ? slice.color.opacity(0.12) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }

                    // Selected detail
                    if let selected = selectedPieItem {
                        pieDetailView(for: selected)
                    }
                }
            }
        }
    }

    private func pieDetailView(for label: String) -> some View {
        let positions = pieDetailPositions(for: label)
        let summary = pieDetailSummary(for: label)

        return VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack {
                Text("\(label) Detayı")
                    .font(.body)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    withAnimation { selectedPieItem = nil }
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
                        Text(Formatters.formatCurrency(summary.maliyet))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Güncel Değer")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(Formatters.formatCurrency(summary.deger))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    KZBadge(value: summary.kz, percentage: summary.kzPct)
                }
            }

            ForEach(positions) { pos in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pos.islem)
                            .font(.body)
                            .fontWeight(.medium)
                        HStack(spacing: 6) {
                            if pieMode == .kasa {
                                Text(pos.tip)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(pos.kasaTip)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Text("\(Formatters.formatDecimal(pos.toplamAdet)) adet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(Formatters.formatCurrency(pos.guncelDeger))
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

    private var portfolioValueChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Portföy Değer Değişimi")
                    .font(.headline)
                if cumulativeValues.isEmpty {
                    Text("Veri bulunamadı")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(height: 250)
                } else {
                    Chart(cumulativeValues, id: \.0) { item in
                        LineMark(
                            x: .value("Tarih", item.0),
                            y: .value("Değer", item.1)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value("Tarih", item.0),
                            y: .value("Değer", item.1)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(Formatters.formatCurrency(v))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 250)
                }
            }
        }
    }

    private var typeData: [(tip: String, total: Double)] {
        Dictionary(grouping: transactions, by: \.tip)
            .map { (tip: $0.key, total: $0.value.filter(\.isPositive).reduce(0) { $0 + $1.tutarTL }) }
            .sorted { $0.total > $1.total }
    }

    private var investmentByTypeChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tip Bazlı Yatırım Tutarları")
                    .font(.headline)

                Chart(typeData, id: \.tip) { item in
                    BarMark(
                        x: .value("Tutar", item.total),
                        y: .value("Tip", item.tip)
                    )
                    .foregroundStyle(Color.forType(item.tip))
                    .annotation(position: .trailing) {
                        Text(Formatters.formatCurrency(item.total))
                            .font(.caption2)
                    }
                }
                .frame(height: CGFloat(typeData.count * 40 + 20))
            }
        }
    }

    private var monthlyData: [(month: String, giris: Double, cikis: Double)] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        let grouped = Dictionary(grouping: transactions) { df.string(from: $0.tarih) }
        return grouped.map { key, txs in
            let giris = txs.filter(\.isPositive).reduce(0) { $0 + $1.tutarTL }
            let cikis = txs.filter { !$0.isPositive }.reduce(0) { $0 + $1.tutarTL }
            return (key, giris, cikis)
        }.sorted { $0.month < $1.month }
    }

    private var monthlyFlowChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Aylık Giriş / Çıkış")
                    .font(.headline)

                Chart {
                    ForEach(monthlyData, id: \.month) { item in
                        BarMark(
                            x: .value("Ay", item.month),
                            y: .value("Tutar", item.giris)
                        )
                        .foregroundStyle(.green)
                        .position(by: .value("Tür", "Giriş"))

                        BarMark(
                            x: .value("Ay", item.month),
                            y: .value("Tutar", item.cikis)
                        )
                        .foregroundStyle(.red)
                        .position(by: .value("Tür", "Çıkış"))
                    }
                }
                .frame(height: 200)
            }
        }
    }
}
