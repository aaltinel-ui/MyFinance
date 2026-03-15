import SwiftUI
import SwiftData
import Charts

struct GoldDetailView: View {
    @Query(sort: \Transaction.tarih) private var transactions: [Transaction]
    @Query(sort: \ExchangeRate.tarih) private var exchangeRates: [ExchangeRate]
    @State private var calculator = PortfolioCalculator()

    private var latestRate: ExchangeRate? { exchangeRates.last }

    private var goldPositions: [InstrumentPosition] {
        calculator.goldPositions()
    }

    private var totalGoldValue: Double {
        goldPositions.reduce(0) { $0 + $1.guncelDeger }
    }

    private var totalGoldCost: Double {
        goldPositions.reduce(0) { $0 + $1.toplamMaliyet }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    distributionChart
                    detailsList
                    priceHistoryChart
                }
                .padding()
            }
            .navigationTitle("Altın Varlıklarım")
            .onAppear { recalculate() }
        }
    }

    private var summaryCard: some View {
        CardView {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.yellow)
                    Text("Toplam Altın Değeri")
                        .font(.headline)
                }
                Text(Formatters.formatCurrency(totalGoldValue))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                KZBadge(value: totalGoldValue - totalGoldCost, percentage: totalGoldCost > 0 ? ((totalGoldValue - totalGoldCost) / totalGoldCost * 100) : 0)
            }
        }
    }

    private var distributionChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Altın Dağılımı")
                    .font(.headline)

                Chart(goldPositions) { pos in
                    SectorMark(
                        angle: .value("Değer", pos.guncelDeger),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Tür", pos.islem))
                }
                .chartForegroundStyleScale(range: [.yellow, .orange, .brown, .mint])
                .frame(height: 200)
            }
        }
    }

    private var detailsList: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Detay")
                    .font(.headline)
                ForEach(goldPositions) { pos in
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(pos.islem)
                                    .font(.subheadline).fontWeight(.medium)
                                Text("\(Formatters.formatDecimal(pos.toplamAdet)) adet")
                                    .font(.title3).fontWeight(.bold).foregroundStyle(.yellow)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(Formatters.formatCurrency(pos.guncelDeger))
                                    .font(.subheadline).fontWeight(.medium)
                                KZBadge(value: pos.karZarar, percentage: pos.karZararYuzdesi)
                            }
                        }
                        HStack {
                            Text("Ort. Alış: \(Formatters.formatCurrencyDetailed(pos.ortalamaAlisFiyati))")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text("Güncel: \(Formatters.formatCurrencyDetailed(pos.guncelFiyat))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ProgressBarView(
                            label: "",
                            value: pos.guncelDeger,
                            total: totalGoldValue,
                            color: .yellow
                        )
                        Divider()
                    }
                }
            }
        }
    }

    private var priceHistoryChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Altın Fiyat Grafiği")
                    .font(.headline)
                let goldRates = exchangeRates.compactMap { rate -> (date: Date, price: Double)? in
                    guard let price = rate.altinGram else { return nil }
                    return (rate.tarih, price)
                }
                if !goldRates.isEmpty {
                    Chart(goldRates, id: \.date) { item in
                        LineMark(
                            x: .value("Tarih", item.date),
                            y: .value("Fiyat", item.price)
                        )
                        .foregroundStyle(.yellow)
                        AreaMark(
                            x: .value("Tarih", item.date),
                            y: .value("Fiyat", item.price)
                        )
                        .foregroundStyle(.yellow.opacity(0.1))
                    }
                    .frame(height: 200)
                } else {
                    Text("Fiyat verisi bulunamadı")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(height: 200)
                }
            }
        }
    }

    private func recalculate() {
        calculator.calculate(transactions: transactions, latestRates: latestRate)
    }
}
