import SwiftUI
import Charts

struct KasaDetailView: View {
    @AppStorage("hideBalances") private var hideBalances = false
    let kasaTip: String
    let calculator: PortfolioCalculator

    private var kasa: KasaSummary? {
        calculator.kasaSummaries.first { $0.kasaTip == kasaTip }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let kasa {
                    summaryCard(kasa)
                    distributionChart(kasa)
                    positionsListCard(kasa)
                }
            }
            .padding()
        }
        .navigationTitle(kasaTip)
    }

    private func summaryCard(_ kasa: KasaSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Toplam Değer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(Formatters.maskedCurrency(kasa.guncelDeger))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                KZBadge(value: kasa.karZarar, percentage: kasa.karZararYuzdesi)
                HStack {
                    Text("Maliyet:")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(Formatters.maskedCurrency(kasa.toplamMaliyet))
                        .font(.caption).fontWeight(.medium)
                }
            }
        }
    }

    private func distributionChart(_ kasa: KasaSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Dağılım")
                    .font(.headline)
                let grouped = Dictionary(grouping: kasa.positions, by: \.tip)
                let typeData = grouped.map { (tip: $0.key, deger: $0.value.reduce(0) { $0 + $1.guncelDeger }) }
                    .sorted { $0.deger > $1.deger }

                Chart(typeData, id: \.tip) { item in
                    SectorMark(
                        angle: .value("Değer", item.deger),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(Color.forType(item.tip))
                }
                .frame(height: 200)

                ForEach(typeData, id: \.tip) { item in
                    ProgressBarView(
                        label: item.tip,
                        value: item.deger,
                        total: kasa.guncelDeger,
                        color: Color.forType(item.tip)
                    )
                }
            }
        }
    }

    private func positionsListCard(_ kasa: KasaSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pozisyonlar")
                    .font(.headline)
                ForEach(kasa.positions) { pos in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(pos.islem)
                                .font(.subheadline).fontWeight(.medium)
                            Text("\(Formatters.formatDecimal(pos.toplamAdet)) adet")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(Formatters.maskedCurrency(pos.guncelDeger))
                                .font(.subheadline).fontWeight(.medium)
                            KZBadge(value: pos.karZarar, percentage: pos.karZararYuzdesi)
                        }
                    }
                    Divider()
                }
            }
        }
    }
}
