import SwiftUI
import SwiftData
import Charts

struct FitreZekatReportView: View {
    @AppStorage("hideBalances") private var hideBalances = false
    @Query(sort: \FitreZekat.tarih, order: .reverse) private var records: [FitreZekat]

    private var byPerson: [(kisi: String, tutar: Double)] {
        Dictionary(grouping: records, by: \.kisiAdi)
            .map { (kisi: $0.key, tutar: $0.value.reduce(0) { $0 + $1.tutar }) }
            .sorted { $0.tutar > $1.tutar }
    }

    private var byType: [(tur: String, tutar: Double)] {
        Dictionary(grouping: records, by: \.tur)
            .map { (tur: $0.key, tutar: $0.value.reduce(0) { $0 + $1.tutar }) }
            .sorted { $0.tutar > $1.tutar }
    }

    private var totalAmount: Double { records.reduce(0) { $0 + $1.tutar } }
    private let personColors: [Color] = [.green, .teal, .blue, .purple, .orange, .pink, .indigo, .brown]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Toplam Fitre/Zekât").font(.subheadline).foregroundStyle(.secondary)
                        Text(Formatters.maskedCurrency(totalAmount)).font(.largeTitle).fontWeight(.bold)
                        Text("\(records.count) kayıt • \(byPerson.count) kişi").font(.subheadline).foregroundStyle(.secondary)
                    }
                }

                // Fitre vs Zekat
                if !byType.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Tür Dağılımı").font(.title3).fontWeight(.bold)
                            Chart(byType, id: \.tur) { item in
                                SectorMark(
                                    angle: .value("Tutar", item.tutar),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 2
                                )
                                .foregroundStyle(item.tur == "Fitre" ? Color.green : Color.teal)
                                .annotation(position: .overlay) {
                                    let pct = totalAmount > 0 ? item.tutar / totalAmount * 100 : 0
                                    VStack(spacing: 2) {
                                        Text(item.tur).font(.caption).fontWeight(.bold)
                                        Text("%\(Int(pct))").font(.caption)
                                        Text(Formatters.maskedCurrency(item.tutar)).font(.caption2)
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                            .frame(height: 200)

                            ForEach(byType, id: \.tur) { item in
                                let pct = totalAmount > 0 ? item.tutar / totalAmount * 100 : 0
                                HStack {
                                    Circle().fill(item.tur == "Fitre" ? Color.green : Color.teal).frame(width: 10, height: 10)
                                    Text(item.tur).font(.body)
                                    Spacer()
                                    Text("%\(Int(pct))").font(.subheadline).foregroundStyle(.secondary)
                                    Text(Formatters.maskedCurrency(item.tutar)).font(.body).fontWeight(.medium)
                                }
                            }
                        }
                    }
                }

                // By Person
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
                                .foregroundStyle(personColors[byPerson.firstIndex(where: { $0.kisi == item.kisi })! % personColors.count])
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
                                    Circle().fill(personColors[idx % personColors.count]).frame(width: 10, height: 10)
                                    Text(item.kisi).font(.body)
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
        .navigationTitle("Fitre/Zekât Raporları")
    }
}
