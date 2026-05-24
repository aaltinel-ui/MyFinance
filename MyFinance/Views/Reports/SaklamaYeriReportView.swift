import SwiftUI
import SwiftData
import Charts

struct SaklamaSummary: Identifiable {
    let id = UUID()
    let saklamaYeri: String
    let toplamTutar: Double
    let islemSayisi: Int
}

struct SaklamaYeriReportView: View {
    @AppStorage("hideBalances") private var hideBalances = false
    @Query private var transactions: [Transaction]

    private var summaries: [SaklamaSummary] {
        let grouped = Dictionary(grouping: transactions, by: \.nerede)
        return grouped.map { key, txns in
            let toplam = txns.reduce(0.0) { sum, t in
                t.isPositive ? sum + t.tutarTL : sum - t.tutarTL
            }
            return SaklamaSummary(saklamaYeri: key, toplamTutar: toplam, islemSayisi: txns.count)
        }
        .sorted { $0.toplamTutar > $1.toplamTutar }
    }

    private var toplamDeger: Double { summaries.reduce(0) { $0 + max($1.toplamTutar, 0) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SummaryCardView(
                        title: "Toplam Saklama Değeri",
                        value: Formatters.maskedCurrency(toplamDeger),
                        subtitle: "\(summaries.count) saklama yeri",
                        icon: "building.columns.fill",
                        color: .blue
                    )

                    if !summaries.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Saklama Yeri Dağılımı").font(.headline)
                                let positives = summaries.filter { $0.toplamTutar > 0 }
                                Chart(positives, id: \.id) { item in
                                    SectorMark(
                                        angle: .value("Tutar", item.toplamTutar),
                                        innerRadius: .ratio(0.5)
                                    )
                                    .foregroundStyle(by: .value("Yer", item.saklamaYeri))
                                }
                                .frame(height: 200)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Saklama Yeri Detayı").font(.headline)
                                let items = summaries
                                ForEach(items, id: \.id) { item in
                                    saklamaRow(item)
                                }
                            }
                        }
                    } else {
                        ContentUnavailableView("İşlem Yok", systemImage: "building.columns", description: Text("Henüz işlem eklenmemiş."))
                    }
                }
                .padding()
            }
            .navigationTitle("Saklama Yeri Raporu")
        }
    }

    private func saklamaRow(_ item: SaklamaSummary) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "building.columns").foregroundStyle(.blue)
                Text(item.saklamaYeri).font(.subheadline).fontWeight(.medium)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Formatters.maskedCurrency(item.toplamTutar))
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundStyle(item.toplamTutar >= 0 ? Color.primary : Color.red)
                    Text("\(item.islemSayisi) işlem")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            ProgressBarView(label: "", value: max(item.toplamTutar, 0), total: toplamDeger, color: .blue)
            Divider()
        }
    }
}
