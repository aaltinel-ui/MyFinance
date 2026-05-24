import SwiftUI
import SwiftData

struct DividendListView: View {
    @AppStorage("hideBalances") private var hideBalances = false
    @Query(sort: \Dividend.tarih, order: .reverse) private var dividends: [Dividend]
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false
    @State private var editingDividend: Dividend?
    @State private var dividendToDelete: Dividend?
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    @State private var selectedStock: String?

    private var stocks: [String] { Array(Set(dividends.map(\.hisse))).sorted() }

    private var filtered: [Dividend] {
        dividends.filter { div in
            let matchesSearch = searchText.isEmpty || div.hisse.localizedCaseInsensitiveContains(searchText)
            let matchesStock = selectedStock == nil || div.hisse == selectedStock
            return matchesSearch && matchesStock
        }
    }

    private var toplamTutar: Double { filtered.reduce(0) { $0 + $1.toplamTutar } }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Toplam Temettü").font(.caption).foregroundStyle(.secondary)
                        Text(Formatters.maskedCurrency(toplamTutar)).font(.title3).fontWeight(.bold).foregroundStyle(.green)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Kayıt Sayısı").font(.caption).foregroundStyle(.secondary)
                        Text("\(filtered.count)").font(.title3).fontWeight(.bold)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if !stocks.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip("Tümü", isSelected: selectedStock == nil) { selectedStock = nil }
                            ForEach(stocks, id: \.self) { s in
                                filterChip(s, isSelected: selectedStock == s) {
                                    selectedStock = selectedStock == s ? nil : s
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Temettüler (\(filtered.count))") {
                if filtered.isEmpty {
                    Text("Temettü kaydı bulunamadı")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 20)
                } else {
                    ForEach(filtered) { div in
                        NavigationLink(destination: DividendDetailView(dividend: div)) {
                            dividendRow(div)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                dividendToDelete = div; showingDeleteAlert = true
                            } label: { Label("Sil", systemImage: "trash") }
                        }
                        .swipeActions(edge: .leading) {
                            Button { editingDividend = div } label: { Label("Düzenle", systemImage: "pencil") }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Hisse ara...")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showingAddSheet = true } label: { Label("Ekle", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showingAddSheet) { DividendFormView() }
        .sheet(item: $editingDividend) { div in DividendEditView(dividend: div) }
        .alert("Temettüyü Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { dividendToDelete = nil }
            Button("Sil", role: .destructive) {
                if let d = dividendToDelete { context.delete(d); dividendToDelete = nil }
            }
        } message: { Text("Bu temettü kaydı kalıcı olarak silinecek.") }
    }

    private func dividendRow(_ div: Dividend) -> some View {
        HStack {
            Image(systemName: "chart.bar.fill").foregroundStyle(.green).font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(div.hisse).font(.body).fontWeight(.medium)
                Text("\(Formatters.formatDecimal(div.adet)) adet × \(Formatters.formatCurrencyDetailed(div.birimTemettu))")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(Formatters.formatDate(div.tarih)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(Formatters.maskedCurrency(div.toplamTutar))
                .font(.body).fontWeight(.bold).foregroundStyle(.green)
        }
        .padding(.vertical, 2)
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.subheadline)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Color.green : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct DividendDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let dividend: Dividend
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "chart.bar.fill").font(.largeTitle).foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dividend.hisse).font(.title2).fontWeight(.bold)
                        Text(Formatters.formatDate(dividend.tarih)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Temettü Detayı") {
                detailRow("Hisse", dividend.hisse)
                detailRow("Tarih", Formatters.formatDate(dividend.tarih))
                detailRow("Adet", Formatters.formatDecimal(dividend.adet))
                detailRow("Birim Temettü", Formatters.formatCurrencyDetailed(dividend.birimTemettu))
                detailRow("Toplam Tutar", Formatters.maskedCurrency(dividend.toplamTutar))
                if let notlar = dividend.notlar, !notlar.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notlar").font(.subheadline).foregroundStyle(.secondary)
                        Text(notlar)
                    }
                }
            }

            Section {
                Button { showingEditSheet = true } label: {
                    Label("Düzenle", systemImage: "pencil").frame(maxWidth: .infinity, alignment: .center)
                }
                Button(role: .destructive) { showingDeleteAlert = true } label: {
                    Label("Sil", systemImage: "trash").frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Temettü Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) { DividendEditView(dividend: dividend) }
        .alert("Temettüyü Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) { context.delete(dividend); dismiss() }
        } message: { Text("Bu temettü kaydı silinecek.") }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.body).fontWeight(.medium)
        }
    }
}

struct DividendEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var dividend: Dividend

    @State private var tarih = Date()
    @State private var hisse = ""
    @State private var adet = ""
    @State private var birimTemettu = ""
    @State private var notlar = ""

    private let stocks = ["TUPRS", "KCHOL", "AKBNK", "THYAO", "ALFAS", "ARCLK", "FROTO", "SASA"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Temettü Bilgileri") {
                    DatePicker("Tarih", selection: $tarih, displayedComponents: .date)
                    Picker("Hisse", selection: $hisse) {
                        Text("Seçiniz").tag("")
                        ForEach(stocks, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Adet", text: $adet).keyboardType(.decimalPad)
                    TextField("Birim Temettü (TL)", text: $birimTemettu).keyboardType(.decimalPad)
                    HStack {
                        Text("Toplam:")
                        Spacer()
                        let ad = Double(adet.replacingOccurrences(of: ",", with: ".")) ?? 0
                        let bt = Double(birimTemettu.replacingOccurrences(of: ",", with: ".")) ?? 0
                        Text(Formatters.formatCurrencyDetailed(ad * bt)).fontWeight(.bold)
                    }
                }
                Section("Ek Bilgi") {
                    TextField("Notlar", text: $notlar, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle("Temettü Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }.disabled(hisse.isEmpty)
                }
            }
            .onAppear {
                tarih = dividend.tarih; hisse = dividend.hisse
                adet = String(dividend.adet); birimTemettu = String(dividend.birimTemettu)
                notlar = dividend.notlar ?? ""
            }
        }
    }

    private func save() {
        let ad = Double(adet.replacingOccurrences(of: ",", with: ".")) ?? 0
        let bt = Double(birimTemettu.replacingOccurrences(of: ",", with: ".")) ?? 0
        dividend.tarih = tarih; dividend.hisse = hisse
        dividend.adet = ad; dividend.birimTemettu = bt
        dividend.toplamTutar = ad * bt
        dividend.notlar = notlar.isEmpty ? nil : notlar
        dismiss()
    }
}
