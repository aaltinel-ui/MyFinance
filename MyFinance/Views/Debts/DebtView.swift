import SwiftUI
import SwiftData

struct DebtView: View {
    @Query(sort: \Debt.verilenTarih, order: .reverse) private var debts: [Debt]
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false

    private var totalGiven: Double { debts.reduce(0) { $0 + $1.toplamTutar } }
    private var totalReturned: Double { debts.filter(\.isReturned).reduce(0) { $0 + ($1.geriAlimToplamTutar ?? 0) } }
    private var totalPending: Double { debts.filter { !$0.isReturned }.reduce(0) { $0 + $1.toplamTutar } }
    private var totalProfit: Double { debts.compactMap(\.fark).reduce(0, +) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCards
                    debtsList
                }
                .padding()
            }
            .navigationTitle("Borç Takibi")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button { showingAddSheet = true } label: {
                        Label("Ekle", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                DebtFormView()
            }
        }
    }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCardView(
                    title: "Toplam Verilen",
                    value: Formatters.formatCurrency(totalGiven),
                    icon: "arrow.up.circle",
                    color: .red
                )
                SummaryCardView(
                    title: "Geri Alınan",
                    value: Formatters.formatCurrency(totalReturned),
                    icon: "arrow.down.circle",
                    color: .green
                )
            }
            HStack(spacing: 12) {
                SummaryCardView(
                    title: "Bekleyen",
                    value: Formatters.formatCurrency(totalPending),
                    icon: "clock",
                    color: .orange
                )
                SummaryCardView(
                    title: "Toplam Kâr",
                    value: Formatters.formatCurrency(totalProfit),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
        }
    }

    private var debtsList: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Borçlar")
                    .font(.headline)
                ForEach(debts) { debt in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: debt.isReturned ? "checkmark.circle.fill" : "clock.fill")
                                .foregroundStyle(debt.isReturned ? .green : .orange)
                            VStack(alignment: .leading) {
                                Text("\(debt.tip) - \(Formatters.formatDecimal(debt.adet)) adet")
                                    .font(.subheadline).fontWeight(.medium)
                                if let kisi = debt.kpiAdi {
                                    Text(kisi)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(debt.isReturned ? "Geri Alındı" : "Bekliyor")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(debt.isReturned ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Verilen")
                                    .font(.caption2).foregroundStyle(.secondary)
                                Text(Formatters.formatDate(debt.verilenTarih))
                                    .font(.caption)
                                Text(Formatters.formatCurrency(debt.toplamTutar))
                                    .font(.caption).fontWeight(.medium)
                            }
                            Spacer()
                            if debt.isReturned, let geriTarih = debt.alindigiTarih, let geriTutar = debt.geriAlimToplamTutar {
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Geri Alındı")
                                        .font(.caption2).foregroundStyle(.secondary)
                                    Text(Formatters.formatDate(geriTarih))
                                        .font(.caption)
                                    Text(Formatters.formatCurrency(geriTutar))
                                        .font(.caption).fontWeight(.medium)
                                }
                            }
                        }

                        if let fark = debt.fark, let yuzde = debt.farkYuzdesi {
                            HStack {
                                Text("Kâr/Zarar:")
                                    .font(.caption).foregroundStyle(.secondary)
                                KZBadge(value: fark, percentage: yuzde)
                            }
                        }
                        Divider()
                    }
                }
            }
        }
    }
}

struct DebtFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var verilenTarih = Date()
    @State private var verilenTutar = ""
    @State private var tip = ""
    @State private var adet = ""
    @State private var birimFiyat = ""
    @State private var kpiAdi = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Verilen Tarih", selection: $verilenTarih, displayedComponents: .date)
                TextField("Kime?", text: $kpiAdi)
                TextField("Tip (ör: Cumhuriyet, Gram)", text: $tip)
                TextField("Adet", text: $adet).keyboardType(.decimalPad)
                TextField("Birim Fiyat", text: $birimFiyat).keyboardType(.decimalPad)
                TextField("Verilen Tutar (TL)", text: $verilenTutar).keyboardType(.decimalPad)
            }
            .navigationTitle("Yeni Borç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        let ad = Double(adet.replacingOccurrences(of: ",", with: ".")) ?? 0
                        let bf = Double(birimFiyat.replacingOccurrences(of: ",", with: ".")) ?? 0
                        let vt = Double(verilenTutar.replacingOccurrences(of: ",", with: ".")) ?? 0
                        let debt = Debt(verilenTarih: verilenTarih, verilenTutar: vt, tip: tip, adet: ad, birimFiyat: bf, kpiAdi: kpiAdi.isEmpty ? nil : kpiAdi)
                        context.insert(debt)
                        dismiss()
                    }
                    .disabled(tip.isEmpty)
                }
            }
        }
    }
}
