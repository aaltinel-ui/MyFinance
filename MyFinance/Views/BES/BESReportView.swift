import SwiftUI
import SwiftData
import Charts

struct BESReportView: View {
    @Query(sort: \BESHesap.baslangicTarihi) private var hesaplar: [BESHesap]

    private var toplamBirikim: Double { hesaplar.reduce(0) { $0 + $1.birikimTutari } }
    private var toplamDevlet: Double { hesaplar.reduce(0) { $0 + $1.devletKatkisi } }
    private var toplamSirket: Double { hesaplar.reduce(0) { $0 + $1.sirketKatkisi } }
    private var toplamFon: Double { hesaplar.reduce(0) { $0 + $1.fonDegeri } }
    private var toplamDeger: Double { hesaplar.reduce(0) { $0 + $1.toplamDeger } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SummaryCardView(
                        title: "Toplam BES Değeri",
                        value: Formatters.formatCurrency(toplamDeger),
                        subtitle: "\(hesaplar.count) hesap",
                        icon: "building.columns.fill",
                        color: .purple
                    )

                    if !hesaplar.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Değer Dağılımı").font(.headline)

                                ProgressBarView(label: "Birikim Tutarı", value: toplamBirikim, total: toplamDeger, color: .blue)
                                ProgressBarView(label: "Devlet Katkısı", value: toplamDevlet, total: toplamDeger, color: .orange)
                                ProgressBarView(label: "Şirket Katkısı", value: toplamSirket, total: toplamDeger, color: .green)
                                ProgressBarView(label: "Fon Değeri", value: toplamFon, total: toplamDeger, color: .purple)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Şirket Bazlı Dağılım").font(.headline)
                                Chart(hesaplar, id: \.id) { hesap in
                                    BarMark(
                                        x: .value("Şirket", hesap.sirketAdi),
                                        y: .value("Değer", hesap.toplamDeger)
                                    )
                                    .foregroundStyle(by: .value("Şirket", hesap.sirketAdi))
                                }
                                .frame(height: 180)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Hesap Listesi").font(.headline)
                                ForEach(hesaplar) { hesap in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(hesap.sirketAdi).font(.subheadline).fontWeight(.medium)
                                            Text(hesap.planAdi).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(Formatters.formatCurrency(hesap.toplamDeger))
                                            .font(.subheadline).fontWeight(.bold).foregroundStyle(.purple)
                                    }
                                    Divider()
                                }
                            }
                        }
                    } else {
                        ContentUnavailableView("BES Hesabı Yok", systemImage: "building.columns", description: Text("Henüz BES hesabı eklenmemiş."))
                    }
                }
                .padding()
            }
            .navigationTitle("BES Raporu")
        }
    }
}
