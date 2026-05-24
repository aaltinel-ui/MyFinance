import SwiftUI
import SwiftData
import Charts

struct DebtReportView: View {
    @AppStorage("hideBalances") private var hideBalances = false
    @Query(sort: \Debt.verilenTarih, order: .reverse) private var debts: [Debt]

    private var byPerson: [(kisi: String, tutar: Double)] {
        Dictionary(grouping: debts, by: \.kpiAdi)
            .map { (kisi: $0.key, tutar: $0.value.reduce(0) { $0 + $1.toplamTutar }) }
            .sorted { $0.tutar > $1.tutar }
    }

    private var byType: [(tip: String, tutar: Double)] {
        Dictionary(grouping: debts, by: \.tip)
            .map { (tip: $0.key, tutar: $0.value.reduce(0) { $0 + $1.toplamTutar }) }
            .sorted { $0.tutar > $1.tutar }
    }

    private var totalAmount: Double { debts.reduce(0) { $0 + $1.toplamTutar } }
    private var acikCount: Int { debts.filter { $0.durum == BorcDurum.acik.rawValue }.count }
    private var kismiCount: Int { debts.filter { $0.durum == BorcDurum.kismi.rawValue }.count }
    private var tamamCount: Int { debts.filter { $0.durum == BorcDurum.tamamlandi.rawValue }.count }

    private let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .teal, .indigo, .brown, .cyan]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Özet").font(.headline)
                        HStack(spacing: 16) {
                            VStack {
                                Text("\(debts.count)").font(.title).fontWeight(.bold)
                                Text("Toplam").font(.caption).foregroundStyle(.secondary)
                            }
                            VStack {
                                Text("\(acikCount)").font(.title).fontWeight(.bold).foregroundStyle(.orange)
                                Text("Açık").font(.caption).foregroundStyle(.secondary)
                            }
                            VStack {
                                Text("\(kismiCount)").font(.title).fontWeight(.bold).foregroundStyle(.blue)
                                Text("Kısmi").font(.caption).foregroundStyle(.secondary)
                            }
                            VStack {
                                Text("\(tamamCount)").font(.title).fontWeight(.bold).foregroundStyle(.green)
                                Text("Tamam").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // By person pie chart
                if !byPerson.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Kişi Bazlı Dağılım").font(.title3).fontWeight(.bold)
                            Chart(byPerson, id: \.kisi) { item in
                                SectorMark(
                                    angle: .value("Tutar", item.tutar),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 2
                                )
                                .foregroundStyle(colors[byPerson.firstIndex(where: { $0.kisi == item.kisi })! % colors.count])
                                .annotation(position: .overlay) {
                                    let pct = totalAmount > 0 ? item.tutar / totalAmount * 100 : 0
                                    if pct > 8 {
                                        VStack(spacing: 2) {
                                            Text(item.kisi).font(.caption).fontWeight(.bold)
                                            Text("%\(Int(pct))").font(.caption2)
                                        }
                                        .foregroundStyle(.white)
                                    }
                                }
                            }
                            .frame(height: 240)

                            ForEach(Array(byPerson.enumerated()), id: \.element.kisi) { idx, item in
                                let pct = totalAmount > 0 ? item.tutar / totalAmount * 100 : 0
                                HStack {
                                    Circle().fill(colors[idx % colors.count]).frame(width: 10, height: 10)
                                    Text(item.kisi).font(.body)
                                    Spacer()
                                    Text("%\(Int(pct))").font(.subheadline).foregroundStyle(.secondary)
                                    Text(Formatters.maskedCurrency(item.tutar)).font(.body).fontWeight(.medium)
                                }
                            }
                        }
                    }
                }

                // By type pie chart
                if !byType.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Tip Bazlı Dağılım").font(.title3).fontWeight(.bold)
                            Chart(byType, id: \.tip) { item in
                                SectorMark(
                                    angle: .value("Tutar", item.tutar),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 2
                                )
                                .foregroundStyle(colors[(byType.firstIndex(where: { $0.tip == item.tip })! + 3) % colors.count])
                                .annotation(position: .overlay) {
                                    let pct = totalAmount > 0 ? item.tutar / totalAmount * 100 : 0
                                    if pct > 8 {
                                        VStack(spacing: 2) {
                                            Text(item.tip).font(.caption).fontWeight(.bold)
                                            Text("%\(Int(pct))").font(.caption2)
                                        }
                                        .foregroundStyle(.white)
                                    }
                                }
                            }
                            .frame(height: 240)

                            ForEach(Array(byType.enumerated()), id: \.element.tip) { idx, item in
                                let pct = totalAmount > 0 ? item.tutar / totalAmount * 100 : 0
                                HStack {
                                    Circle().fill(colors[(idx + 3) % colors.count]).frame(width: 10, height: 10)
                                    Text(item.tip).font(.body)
                                    Spacer()
                                    Text("%\(Int(pct))").font(.subheadline).foregroundStyle(.secondary)
                                    Text(Formatters.maskedCurrency(item.tutar)).font(.body).fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Borç Raporları")
    }
}
