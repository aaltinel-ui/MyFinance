import SwiftUI
import SwiftData
import Charts

struct PortfolioChartView: View {
    @Query(sort: \Transaction.tarih) private var transactions: [Transaction]
    @Query(sort: \ExchangeRate.tarih) private var exchangeRates: [ExchangeRate]
    @State private var selectedTimeRange: TimeRange = .all

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
                    portfolioValueChart
                    investmentByTypeChart
                    monthlyFlowChart
                }
                .padding()
            }
            .navigationTitle("Portföy Grafikleri")
        }
    }

    private var timeRangePicker: some View {
        Picker("Zaman", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
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

    private var investmentByTypeChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tip Bazlı Yatırım Tutarları")
                    .font(.headline)

                let typeData = Dictionary(grouping: transactions, by: \.tip)
                    .map { (tip: $0.key, total: $0.value.filter(\.isPositive).reduce(0) { $0 + $1.tutarTL }) }
                    .sorted { $0.total > $1.total }

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

    private var monthlyFlowChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Aylık Giriş / Çıkış")
                    .font(.headline)

                let df = DateFormatter()
                df.dateFormat = "yyyy-MM"
                let grouped = Dictionary(grouping: transactions) { df.string(from: $0.tarih) }
                let monthly = grouped.map { key, txs -> (month: String, giris: Double, cikis: Double) in
                    let giris = txs.filter(\.isPositive).reduce(0) { $0 + $1.tutarTL }
                    let cikis = txs.filter { !$0.isPositive }.reduce(0) { $0 + $1.tutarTL }
                    return (key, giris, cikis)
                }.sorted { $0.month < $1.month }

                Chart {
                    ForEach(monthly, id: \.month) { item in
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
