import SwiftUI
import SwiftData
import Charts

struct DividendReportView: View {
    @Query(sort: \Dividend.tarih, order: .reverse) private var dividends: [Dividend]
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false

    private var totalDividend: Double {
        dividends.reduce(0) { $0 + $1.toplamTutar }
    }

    private var byStock: [(stock: String, total: Double)] {
        let grouped = Dictionary(grouping: dividends, by: \.hisse)
        return grouped.map { (stock: $0.key, total: $0.value.reduce(0) { $0 + $1.toplamTutar }) }
            .sorted { $0.total > $1.total }
    }

    private var byMonth: [(month: String, total: Double)] {
        let df = DateFormatter()
        df.dateFormat = "MMM yy"
        df.locale = Locale(identifier: "tr_TR")
        let grouped = Dictionary(grouping: dividends) { df.string(from: $0.tarih) }
        return grouped.map { (month: $0.key, total: $0.value.reduce(0) { $0 + $1.toplamTutar }) }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    monthlyChart
                    stockDistribution
                    dividendsList
                }
                .padding()
            }
            .navigationTitle("Temettü Gelirleri")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Ekle", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                DividendFormView()
            }
        }
    }

    private var summaryCard: some View {
        SummaryCardView(
            title: "Toplam Temettü Geliri",
            value: Formatters.formatCurrency(totalDividend),
            subtitle: "\(dividends.count) temettü ödemesi",
            icon: "chart.bar.fill",
            color: .green
        )
    }

    private var monthlyChart: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Aylık Temettü")
                    .font(.headline)
                Chart(dividends, id: \.id) { div in
                    BarMark(
                        x: .value("Tarih", div.tarih, unit: .month),
                        y: .value("Tutar", div.toplamTutar)
                    )
                    .foregroundStyle(by: .value("Hisse", div.hisse))
                }
                .frame(height: 200)
            }
        }
    }

    private var stockDistribution: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hisse Bazlı Dağılım")
                    .font(.headline)
                ForEach(byStock, id: \.stock) { item in
                    ProgressBarView(
                        label: item.stock,
                        value: item.total,
                        total: totalDividend,
                        color: .green
                    )
                }
            }
        }
    }

    private var dividendsList: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tüm Temettüler")
                    .font(.headline)
                ForEach(dividends) { div in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(div.hisse)
                                .font(.subheadline).fontWeight(.medium)
                            Text(Formatters.formatDate(div.tarih))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(Formatters.formatCurrency(div.toplamTutar))
                                .font(.subheadline).fontWeight(.medium).foregroundStyle(.green)
                            Text("\(Formatters.formatDecimal(div.adet)) x \(Formatters.formatCurrencyDetailed(div.birimTemettu))")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) { context.delete(div) } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                    Divider()
                }
            }
        }
    }
}

struct DividendFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var tarih = Date()
    @State private var hisse = ""
    @State private var adet = ""
    @State private var birimTemettu = ""

    private let stocks = ["TUPRS", "KCHOL", "AKBNK", "THYAO", "ALFAS", "ARCLK"]

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Tarih", selection: $tarih, displayedComponents: .date)
                Picker("Hisse", selection: $hisse) {
                    Text("Seçiniz").tag("")
                    ForEach(stocks, id: \.self) { s in
                        Text(s).tag(s)
                    }
                }
                TextField("Adet", text: $adet)
                    .keyboardType(.decimalPad)
                TextField("Birim Temettü (TL)", text: $birimTemettu)
                    .keyboardType(.decimalPad)

                let ad = Double(adet.replacingOccurrences(of: ",", with: ".")) ?? 0
                let bt = Double(birimTemettu.replacingOccurrences(of: ",", with: ".")) ?? 0
                HStack {
                    Text("Toplam:")
                    Spacer()
                    Text(Formatters.formatCurrencyDetailed(ad * bt))
                        .fontWeight(.bold)
                }
            }
            .navigationTitle("Yeni Temettü")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        let ad = Double(adet.replacingOccurrences(of: ",", with: ".")) ?? 0
                        let bt = Double(birimTemettu.replacingOccurrences(of: ",", with: ".")) ?? 0
                        let div = Dividend(tarih: tarih, hisse: hisse, adet: ad, birimTemettu: bt)
                        context.insert(div)
                        dismiss()
                    }
                    .disabled(hisse.isEmpty)
                }
            }
        }
    }
}
